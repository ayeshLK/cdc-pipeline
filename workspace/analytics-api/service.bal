import ballerina/http;

import ayesh/commons;

listener http:Listener httpListener = check http:getDefaultListener();

service /analytics on httpListener {

    resource function get merchant/[int merchantId]() returns commons:AggregatedSales[]|error {
        return getSummarizedMerchantAnalytics(merchantId);
    }

    resource function get category/[string category]() returns commons:AggregatedSales[]|error {
        return getSummarizedCategoryAnalytics(category);
    }
}

isolated function getSummarizedMerchantAnalytics(int merchantId) returns commons:AggregatedSales[]|error {
    commons:AggregatedSales[] results = check getAnalyticsByMerchant(merchantId);

    map<commons:AggregateSummary> intermediateSummary = getMerchantBasedSummary(results);
    table<MerchantBasedUniqueKey> key(timestamp, category) uniqueKeys = table key(timestamp, category)
            from commons:AggregatedSales itm in results
        select {timestamp: itm.timestamp, category: itm.category}
        on conflict ();

    commons:AggregatedSales[] aggregated = [];
    foreach var entry in uniqueKeys {
        string 'key = string `${entry.timestamp.toJsonString()}|${entry.category}`;
        commons:AggregateSummary? summary = intermediateSummary['key];
        if summary is () {
            continue;
        }
        commons:AggregatedSales summarizedSales = {
            timestamp: entry.timestamp,
            merchantId: merchantId,
            category: entry.category,
            totalRevenue: summary.totalRevenue,
            totalItems: summary.totalItems,
            orderCount: summary.orderCount
        };
        aggregated.push(summarizedSales);
    }

    return aggregated;
};

isolated function getMerchantBasedSummary(commons:AggregatedSales[] items) returns map<commons:AggregateSummary> {
    return map from commons:AggregatedSales itm in items
        let string groupId = string `${itm.timestamp.toJsonString()}|${itm.category}`
        let decimal revenue = itm.totalRevenue
        let int quantity = itm.totalItems
        let int count = itm.orderCount
        group by groupId
        select [
            groupId,
            {
                totalRevenue: sum(revenue),
                totalItems: sum(quantity),
                orderCount: sum(count)
            }
        ];
}

isolated function getSummarizedCategoryAnalytics(string category) returns commons:AggregatedSales[]|error {
    commons:AggregatedSales[] results = check getAnalyticsByCategory(category);

    map<commons:AggregateSummary> intermediateSummary = getCategoryBasedSummary(results);
    table<CategoryBasedUniqueKey> key(timestamp, merchantId) uniqueKeys = table key(timestamp, merchantId)
            from commons:AggregatedSales itm in results
        select {timestamp: itm.timestamp, merchantId: itm.merchantId}
        on conflict ();

    commons:AggregatedSales[] aggregated = [];
    foreach var entry in uniqueKeys {
        string 'key = string `${entry.timestamp.toJsonString()}|${entry.merchantId}`;
        commons:AggregateSummary? summary = intermediateSummary['key];
        if summary is () {
            continue;
        }
        commons:AggregatedSales summarizedSales = {
            timestamp: entry.timestamp,
            merchantId: entry.merchantId,
            category: category,
            totalRevenue: summary.totalRevenue,
            totalItems: summary.totalItems,
            orderCount: summary.orderCount
        };
        aggregated.push(summarizedSales);
    }

    return aggregated;
};

isolated function getCategoryBasedSummary(commons:AggregatedSales[] items) returns map<commons:AggregateSummary> {
    return map from commons:AggregatedSales itm in items
        let string groupId = string `${itm.timestamp.toJsonString()}|${itm.merchantId}`
        let decimal revenue = itm.totalRevenue
        let int quantity = itm.totalItems
        let int count = itm.orderCount
        group by groupId
        select [
            groupId,
            {
                totalRevenue: sum(revenue),
                totalItems: sum(quantity),
                orderCount: sum(count)
            }
        ];
}
