import ballerinax/kafka;

final kafka:Producer producer = check new (kafka.bootstrapServers, acks = "all");

isolated function produceMessage(string tableName, record {} entry) returns error? {
    string topic = string `${kafka.topicPrefix}-${tableName}`;
    byte[] value = entry.toJsonString().toBytes();
    check producer->send({topic, value});
    check producer->'flush();
}
