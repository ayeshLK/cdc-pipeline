import ballerina/time;

import ayesh/commons;

isolated function updateEventReceivedTime() {
    lock {
        lastEventReceivedTime = time:utcNow();
    }
}

isolated function getLastEventReceivedTime() returns time:Utc? {
    lock {
        return lastEventReceivedTime;
    }
}

public isolated function isLive() returns boolean|error {
    time:Utc? lastEventReceivedTime = getLastEventReceivedTime();
    if lastEventReceivedTime is () {
        return false;
    }
    if time:utcDiffSeconds(lastEventReceivedTime, time:utcNow()) > livenessInterval {
        return false;
    }
    return true;
}

isolated function retrieveProduct(int productId) returns commons:Product|error? {
    string cacheKey = string `product-${productId}`;
    string? cachedProduct = check retrieveCachedValue(cacheKey);
    if cachedProduct is () {
        return;
    }
    return cachedProduct.fromJsonStringWithType();
}

isolated function retrieveCachedOrder(int orderId) returns commons:Order|error? {
    string cacheKey = string `order-${orderId}`;
    string? cachedOrder = check retrieveCachedValue(cacheKey);
    if cachedOrder is () {
        return;
    }
    return cachedOrder.fromJsonStringWithType();
}

isolated function retrieveCachedValue(string cacheKey) returns string|error? {
    string? cachedValue = check cache->get(cacheKey);
    if cachedValue is string {
        _ = check cache->expire(cacheKey, redis.cacheExpiryInterval);
        return cachedValue;
    }
    return;
}

isolated function createEnrichedItem(commons:OrderItem itm) returns EnrichedOrderItem|error? {
    commons:Order|error? 'order = retrieveCachedOrder(itm.order_id);
    if 'order is () || 'order is error {
        commons:logWarnOrError("Could not find the order for the order-item from the cache, hence pushing the event to the dead-letter topic",
                'error = 'order, itm = itm);
        check producer->send({topic: kafka.deadLetterItemsTopic, value: itm});
        return;
    }

    commons:Product|error? product = retrieveProduct(itm.product_id);
    if product is () || product is error {
        commons:logWarnOrError("Could not find the relevant product for the order-item from the cache, hence pushing the event to the dead-letter topic",
                'error = 'product, itm = itm);
        check producer->send({topic: kafka.deadLetterItemsTopic, value: itm});
        return;
    }

    return {
        orderId: itm.order_id,
        orderItemId: itm.order_item_id,
        merchantId: 'order.merchant_id,
        productId: itm.product_id,
        category: product.category,
        quantity: itm.quantity,
        price: itm.price,
        eventTime: check time:utcFromCivil(check time:civilFromString('order.created_at))
    };
}

isolated function getSummaryResults(EnrichedOrderItem[] items) returns map<commons:AggregateSummary> {
    return map from EnrichedOrderItem itm in items
        let string groupId = string `${itm.eventTime.toJsonString()}|${itm.merchantId}|${itm.category}`
        let decimal revFromItm = itm.price * itm.quantity
        let int quantity = itm.quantity
        let int count = 1
        group by groupId
        select [
            groupId,
            {
                totalRevenue: sum(revFromItm),
                totalItems: sum(quantity),
                orderCount: sum(count)
            }
        ];
}

isolated function updateAnalyticsDb(commons:AggregatedSales[] sales) returns error? {
    foreach var itm in sales {
        int[]|error? result = check analytics->/merchantsalesummaries.post([toMerchantSaleSummaryInsert(itm)]);
        if result is error {
            commons:logWarnOrError("Error occurred while persisting analytics data, hence pushing the event to the dead-letter topic",
                    'error = result, itm = itm);
            check producer->send({topic: kafka.deadLetterAnalysisTopic, value: itm});
        }
    }
}

isolated function insertSalesData(commons:AggregatedSales salesSummary) returns error? {
    _ = check analytics->/merchantsalesummaries.post([toMerchantSaleSummaryInsert(salesSummary)]);
}
