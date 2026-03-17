import ayesh/analyticsdb;
import ayesh/commons;

isolated function toAggregatedSales(analyticsdb:MerchantSaleSummary summary) returns commons:AggregatedSales => {
    timestamp: summary.timeStamp,
    merchantId: summary.merchantId,
    category: summary.category,
    totalRevenue: summary.totalRevenue,
    totalItems: summary.itemsSold,
    orderCount: summary.orderCount
};
