import ayesh/analyticsdb;
import ayesh/commons;

final analyticsdb:Client analytics = check new ();

isolated function insertSalesData(commons:AggregatedSales salesSummary) returns error? {
    _ = check analytics->/merchantsalesummaries.post([toMerchantSaleSummaryInsert(salesSummary)]);
}

isolated function toMerchantSaleSummaryInsert(commons:AggregatedSales salesSummary) returns analyticsdb:MerchantSaleSummaryInsert => {
    timeStamp: salesSummary.timestamp,
    merchantId: salesSummary.merchantId,
    category: salesSummary.category,
    totalRevenue: salesSummary.totalRevenue,
    orderCount: salesSummary.orderCount,
    itemsSold: salesSummary.totalItems,
    lastUpdated: ()
};

