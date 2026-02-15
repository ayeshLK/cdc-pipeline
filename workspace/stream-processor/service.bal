import ballerina/log;
import ballerina/time;
import ballerinax/kafka;

import ayesh/commons;

listener kafka:Listener kafkaListener = new (kafka.bootstrapServers, {
    groupId: "cdc-events-receiver",
    topics: [
        "cdc-order_items"
    ],
    pollingInterval: 60.0,
    pollingTimeout: 15.0,
    autoCommit: false
});

service on kafkaListener {

    isolated function init() returns error? {
        updateEventReceivedTime();
    }

    isolated remote function onConsumerRecord(commons:OrderItem[] orderItems, kafka:Caller caller) returns error? {
        log:printDebug("Received set of events", received = orderItems);
        updateEventReceivedTime();

        EnrichedOrderItem[] enrichedOrderItems = [];
        foreach commons:OrderItem message in orderItems {
            EnrichedOrderItem? enriched = check createEnrichedItem(message);
            if enriched is EnrichedOrderItem {
                enrichedOrderItems.push(enriched);
            }
        }

        map<commons:AggregateSummary> intermediateSummary = getSummaryResults(enrichedOrderItems);
        table<UniqueKey> key(eventTime, merchantId, category) uniqueKeys = table key(eventTime, merchantId, category)
            from EnrichedOrderItem itm in enrichedOrderItems
            select {eventTime: itm.eventTime, merchantId: itm.merchantId, category: itm.category}
            on conflict ();

        commons:AggregatedSales[] aggregatedSummary = [];
        foreach var entry in uniqueKeys {
            string 'key = string `${entry.eventTime.toJsonString()}|${entry.merchantId}|${entry.category}`;
            record {|
                decimal totalRevenue;
                int totalItems;
                int orderCount;
            |}? summary = intermediateSummary['key];
            if summary is () {
                continue;
            }

            commons:AggregatedSales sales = {
                timestamp: entry.eventTime,
                category: entry.category,
                merchantId: entry.merchantId,
                totalRevenue: summary.totalRevenue,
                totalItems: summary.totalItems,
                orderCount: summary.orderCount
            };
            aggregatedSummary.push(sales);
        }

        // Asynchronously update the database
        _ = start updateAnalyticsDb(aggregatedSummary.cloneReadOnly());

        return caller->'commit();
    }
}

isolated function createEnrichedItem(commons:OrderItem itm) returns EnrichedOrderItem|error? {
    commons:Order? 'order = check retrieveCachedOrder(itm.order_id);
    if 'order is () {
        log:printWarn("Could not find the order for the order-item from the cache, hence pushing the event to the dead-letter topic", itm = itm);
        check pushOrderItemToDLQ(itm);
        return;
    }

    commons:Product? product = check retrieveProduct(itm.product_id);
    if product is () {
        log:printWarn("Could not find the relevant product for the order-item from the cache, hence pushing the event to the dead-letter topic", itm = itm);
        check pushOrderItemToDLQ(itm);
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
        error? result = insertSalesData(itm);
        if result is error {
            log:printError(
                    "Error occurred while persisting analytics data, hence pushing the event to the dead-letter topic",
                    itm = itm, 'error = result);
            check pushAggregatedSalesToDLQ(itm);
        }
    }
}
