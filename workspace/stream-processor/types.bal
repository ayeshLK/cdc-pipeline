import ballerina/time;

type DbConfig record {|
    string host;
    string user;
    string password;
    string database;
    int port;
|};

type KafkaConfig record {|
    string bootstrapServers;
    string deadLetterItemsTopic;
    string deadLetterAnalysisTopic;
|};

type RedisConfig record {|
    string host;
    int port;
    int cacheExpiryInterval;
|};

type EnrichedOrderItem record {|
    int orderItemId;
    int orderId;
    int merchantId;
    int productId;
    string category;
    int quantity;
    decimal price;
    time:Utc eventTime;
|};

type UniqueKey readonly & record {|
    time:Utc eventTime;
    int merchantId;
    string category;
|};

