import ballerinax/redis;

import ayesh/commons;

final redis:Client cache = check new (connection = {
    host: redis.host,
    port: redis.port
});

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
