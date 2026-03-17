import ballerinax/kafka;
import ballerinax/redis;

final kafka:Producer producer = check new (kafka.bootstrapServers, acks = "all");

final redis:Client cache = check new (connection = {
    host: redis.host,
    port: redis.port
});
