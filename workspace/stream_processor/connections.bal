import ballerinax/kafka;
import ballerinax/redis;

import ayesh/analyticsdb;

final redis:Client cache = check new (connection = {
    host: redis.host,
    port: redis.port
});

final kafka:Producer producer = check new (kafka.bootstrapServers, acks = "all");

final analyticsdb:Client analytics = check new;
