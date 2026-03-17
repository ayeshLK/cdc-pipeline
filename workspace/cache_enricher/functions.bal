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

isolated function cacheProduct(commons:Product product) returns error? {
    string cacheKey = string `product-${product.product_id}`;
    string 'value = product.toJsonString();
    return addEntryToCache(cacheKey, 'value);
}

isolated function cacheOrder(commons:Order 'order) returns error? {
    string cacheKey = string `order-${'order.order_id}`;
    string 'value = 'order.toJsonString();
    return addEntryToCache(cacheKey, 'value);
}

isolated function addEntryToCache(string 'key, string 'value) returns error? {
    _ = check cache->setEx('key, 'value, redis.cacheExpiryInterval);
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
