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

service /health on httpListener {

    resource function get liveness() returns http:Ok {
        // todo: implement relevant liveness logic here
        return http:OK;
    }
}
