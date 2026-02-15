// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.

import ballerina/time;

public type MerchantSaleSummary record {|
    readonly int id;
    time:Utc timeStamp;
    int merchantId;
    string category;
    decimal totalRevenue;
    int itemsSold;
    int orderCount;
    time:Utc? lastUpdated;
|};

public type MerchantSaleSummaryOptionalized record {|
    int id?;
    time:Utc timeStamp?;
    int merchantId?;
    string category?;
    decimal totalRevenue?;
    int itemsSold?;
    int orderCount?;
    time:Utc? lastUpdated?;
|};

public type MerchantSaleSummaryTargetType typedesc<MerchantSaleSummaryOptionalized>;

public type MerchantSaleSummaryInsert record {|
    time:Utc timeStamp;
    int merchantId;
    string category;
    decimal totalRevenue;
    int itemsSold;
    int orderCount;
    time:Utc? lastUpdated;
|};

public type MerchantSaleSummaryUpdate record {|
    time:Utc timeStamp?;
    int merchantId?;
    string category?;
    decimal totalRevenue?;
    int itemsSold?;
    int orderCount?;
    time:Utc? lastUpdated?;
|};

