import ayesh/commons;

type KafkaConfig record {|
    string bootstrapServers;
    string deadLetterTopic;
|};

type RedisConfig record {|
    string host;
    int port;
    int cacheExpiryInterval;
|};

type Message commons:Order|commons:Product;
