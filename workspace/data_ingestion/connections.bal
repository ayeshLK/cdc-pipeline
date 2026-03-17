import ballerinax/kafka;

final kafka:Producer producer = check new (kafka.bootstrapServers, acks = "all");
