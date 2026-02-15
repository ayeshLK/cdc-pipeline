import ballerinax/kafka;
import ayesh/commons;

final kafka:Producer producer = check new (kafka.bootstrapServers, acks = "all");

isolated function pushOrderItemToDLQ(record {} entry) returns error? {
    byte[] value = entry.toJsonString().toBytes();
    return produceKafkaMessage(kafka.deadLetterItemsTopic, value);
}

isolated function pushAggregatedSalesToDLQ(commons:AggregatedSales entry) returns error? {
    byte[] value = entry.toJsonString().toBytes();
    return produceKafkaMessage(kafka.deadLetterAnalysisTopic, value);
}

isolated function produceKafkaMessage(string topic, byte[] value) returns error? {
    check producer->send({topic, value});
    check producer->'flush();
}
