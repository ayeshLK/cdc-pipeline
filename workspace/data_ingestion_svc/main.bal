import ballerina/http;

import ayesh/data_ingestion;

listener http:Listener httpListener = check http:getDefaultListener();

service /health on httpListener {

    resource function get liveness() returns http:Ok|http:ServiceUnavailable|error {
        boolean isLive = check data_ingestion:isLive();
        if isLive {
            return http:OK;
        }
        return http:SERVICE_UNAVAILABLE;
    }
}
