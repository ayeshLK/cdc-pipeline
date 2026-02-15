import ballerina/log;
import ballerinax/kafka;

import ayesh/commons;

listener kafka:Listener kafkaListener = new (kafka.bootstrapServers, {
    groupId: "cdc-cache-events-receiver",
    topics: [
        "cdc-products",
        "cdc-orders"
    ],
    pollingInterval: 30.0,
    pollingTimeout: 15.0,
    autoCommit: false
});

service on kafkaListener {

    isolated function init() returns error? {
        updateEventReceivedTime();
    }

    remote function onConsumerRecord(Message[] messages, kafka:Caller caller) returns error? {
        updateEventReceivedTime();
        foreach var msg in messages {
            check updateCache(msg);
        }
        check caller->'commit();
    }
}

isolated function updateCache(commons:Order|commons:Product entry) returns error? {
    error? cachingResult;
    if entry is commons:Order {
        cachingResult = cacheOrder(entry);
    } else {
        cachingResult = cacheProduct(entry);
    }

    if cachingResult is error {
        log:printWarn("Error occurred while caching entry, hence pushing the event to the dead-letter topic", itm = entry);
        check produceDeadLetterMsg(entry);
    }
}
