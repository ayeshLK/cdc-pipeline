import ballerinax/kafka;

final kafka:Producer producer = check new (kafka.bootstrapServers, acks = "all");

isolated function produceDeadLetterMsg(record {} entry) returns error? {
    string topic = string `${kafka.deadLetterTopic}`;
    byte[] value = entry.toJsonString().toBytes();
    check producer->send({topic, value});
    check producer->'flush();
}
