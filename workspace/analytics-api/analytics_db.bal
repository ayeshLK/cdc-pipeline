import ballerina/persist;

import ayesh/analyticsdb;
import ayesh/commons;

final analyticsdb:Client analytics = check new ();

isolated function getAnalyticsByMerchant(int merchantId) returns commons:AggregatedSales[]|error {
    stream<analyticsdb:MerchantSaleSummary, persist:Error?> summary = analytics->/merchantsalesummaries(
        whereClause = `merchant_id = ${merchantId}`
    );
    return from var item in summary
        select toAggregatedSales(item);
}

isolated function getAnalyticsByCategory(string category) returns commons:AggregatedSales[]|error {
    stream<analyticsdb:MerchantSaleSummary, persist:Error?> summary = analytics->/merchantsalesummaries(
        whereClause = `category = ${category}`
    );
    return from var item in summary
        select toAggregatedSales(item);    
}

isolated function toAggregatedSales(analyticsdb:MerchantSaleSummary summary) returns commons:AggregatedSales => {
    timestamp: summary.timeStamp,
    merchantId: summary.merchantId,
    category: summary.category,
    totalRevenue: summary.totalRevenue,
    totalItems: summary.itemsSold,
    orderCount: summary.orderCount
};

