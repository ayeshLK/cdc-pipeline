import ballerina/log;
import ballerina/time;
import ballerinax/kafka;

import ayesh/commons;

isolated time:Utc? lastEventReceivedTime = ();

listener kafka:Listener kafkaListener = new (kafka.bootstrapServers, {
    groupId: "cdc-events-receiver",
    topics: [
        "cdc-order_items"
    ],
    pollingInterval: 60.0,
    pollingTimeout: 15.0,
    autoCommit: false
});

service on kafkaListener {

    isolated function init() returns error? {
        updateEventReceivedTime();
    }

    isolated remote function onConsumerRecord(commons:OrderItem[] orderItems, kafka:Caller caller) returns error? {
        log:printDebug("Received set of events", received = orderItems);
        updateEventReceivedTime();

        EnrichedOrderItem[] enrichedOrderItems = [];
        foreach commons:OrderItem message in orderItems {
            EnrichedOrderItem? enriched = check createEnrichedItem(message);
            if enriched is EnrichedOrderItem {
                enrichedOrderItems.push(enriched);
            }
        }

        map<commons:AggregateSummary> intermediateSummary = getSummaryResults(enrichedOrderItems);
        table<UniqueKey> key(eventTime, merchantId, category) uniqueKeys = table key(eventTime, merchantId, category)
            from EnrichedOrderItem itm in enrichedOrderItems
            select {eventTime: itm.eventTime, merchantId: itm.merchantId, category: itm.category}
            on conflict ();

        commons:AggregatedSales[] aggregatedSummary = [];
        foreach var entry in uniqueKeys {
            string 'key = string `${entry.eventTime.toJsonString()}|${entry.merchantId}|${entry.category}`;
            record {|
                decimal totalRevenue;
                int totalItems;
                int orderCount;
            |}? summary = intermediateSummary['key];
            if summary is () {
                continue;
            }

            commons:AggregatedSales sales = {
                timestamp: entry.eventTime,
                category: entry.category,
                merchantId: entry.merchantId,
                totalRevenue: summary.totalRevenue,
                totalItems: summary.totalItems,
                orderCount: summary.orderCount
            };
            aggregatedSummary.push(sales);
        }

        // Asynchronously update the database
        _ = start updateAnalyticsDb(aggregatedSummary.cloneReadOnly());

        return caller->'commit();
    }
}
