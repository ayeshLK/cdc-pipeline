import ballerina/time;

public type OrderItem record {|
    int order_item_id;
    int quantity;
    string updated_at;
    decimal price;
    int product_id;
    string created_at;
    int order_id;
|};

public type Order record {|
    string order_status;
    string updated_at;
    string created_at;
    int merchant_id;
    int order_time;
    int customer_id;
    int order_id;
|};

public type Product record {|
    string updated_at;
    int product_id;
    string name;
    string created_at;
    int merchant_id;
    string category;
|};

public type AggregatedSales record {|
    time:Utc timestamp;
    int merchantId;
    string category;
    decimal totalRevenue;
    int totalItems;
    int orderCount;
|};

public type AggregateSummary record {|
    decimal totalRevenue;
    int totalItems;
    int orderCount;
|};
