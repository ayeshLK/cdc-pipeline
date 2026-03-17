import ayesh/stream_processor;
import ayesh/cache_enricher;

import ballerina/http;

listener http:Listener httpListener = check http:getDefaultListener();

service /health on httpListener {

    resource function get liveness() returns http:Ok|http:ServiceUnavailable|error {
        boolean streamProcessorLive = check stream_processor:isLive();
        boolean cacheEnricherLive = check cache_enricher:isLive();
        if streamProcessorLive && cacheEnricherLive {
            return http:OK;
        }
        return http:SERVICE_UNAVAILABLE;
    }
}
