import ayesh/analyticsdb;
import ayesh/commons;

isolated function toMerchantSaleSummaryInsert(commons:AggregatedSales salesSummary) returns analyticsdb:MerchantSaleSummaryInsert => {
    timeStamp: salesSummary.timestamp,
    merchantId: salesSummary.merchantId,
    category: salesSummary.category,
    totalRevenue: salesSummary.totalRevenue,
    orderCount: salesSummary.orderCount,
    itemsSold: salesSummary.totalItems,
    lastUpdated: ()
};
