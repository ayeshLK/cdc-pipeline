type DbConfig record {|
    string hostname;
    int port;
    string username;
    string password;
|};

type KafkaConfig record {|
    string bootstrapServers;
    string topicPrefix;
|};
