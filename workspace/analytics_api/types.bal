import ballerina/time;

type MerchantBasedUniqueKey readonly & record {|
    time:Utc timestamp;
    string category;
|};

type CategoryBasedUniqueKey readonly & record {|
    time:Utc timestamp;
    int merchantId;
|};
