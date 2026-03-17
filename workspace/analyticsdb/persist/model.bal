import ballerina/persist as _;
import ballerina/time;
import ballerinax/persist.sql;

@sql:Name {value: "merchant_sales_summary"}
public type MerchantSaleSummary record {|
    @sql:Generated
    readonly int id;
    @sql:Name {value: "time_stamp"}
    time:Utc timeStamp;
    @sql:Name {value: "merchant_id"}
    int merchantId;
    @sql:Varchar {length: 100}
    string category;
    @sql:Name {value: "total_revenue"}
    @sql:Decimal {precision: [15, 2]}
    decimal totalRevenue;
    @sql:Name {value: "items_sold"}
    int itemsSold;
    @sql:Name {value: "order_count"}
    int orderCount;
    @sql:Name {value: "last_updated"}
    time:Utc? lastUpdated;
|};

