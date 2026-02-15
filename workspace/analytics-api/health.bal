import ballerina/http;

service /health on httpListener {

    resource function get liveness() returns http:Ok {
        // todo: implement relevant liveness logic here
        return http:OK;
    }
}