// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.

import ballerina/jballerina.java;
import ballerina/persist;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerinax/persist.sql as psql;

const MERCHANT_SALE_SUMMARY = "merchantsalesummaries";

public isolated client class Client {
    *persist:AbstractPersistClient;

    private final mysql:Client dbClient;

    private final map<psql:SQLClient> persistClients;

    private final record {|psql:SQLMetadata...;|} & readonly metadata = {
        [MERCHANT_SALE_SUMMARY]: {
            entityName: "MerchantSaleSummary",
            tableName: "merchant_sales_summary",
            fieldMetadata: {
                id: {columnName: "id", dbGenerated: true},
                timeStamp: {columnName: "time_stamp"},
                merchantId: {columnName: "merchant_id"},
                category: {columnName: "category"},
                totalRevenue: {columnName: "total_revenue"},
                itemsSold: {columnName: "items_sold"},
                orderCount: {columnName: "order_count"},
                lastUpdated: {columnName: "last_updated"}
            },
            keyFields: ["id"]
        }
    };

    public isolated function init() returns persist:Error? {
        mysql:Client|error dbClient = new (host = host, user = user, password = password, database = database, port = port, options = connectionOptions);
        if dbClient is error {
            return <persist:Error>error(dbClient.message());
        }
        self.dbClient = dbClient;
        self.persistClients = {[MERCHANT_SALE_SUMMARY]: check new (dbClient, self.metadata.get(MERCHANT_SALE_SUMMARY), psql:MYSQL_SPECIFICS)};
    }

    isolated resource function get merchantsalesummaries(MerchantSaleSummaryTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get merchantsalesummaries/[int id](MerchantSaleSummaryTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post merchantsalesummaries(MerchantSaleSummaryInsert[] data) returns int[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MERCHANT_SALE_SUMMARY);
        }
        sql:ExecutionResult[] result = check sqlClient.runBatchInsertQuery(data);
        return from sql:ExecutionResult inserted in result
            where inserted.lastInsertId != ()
            select <int>inserted.lastInsertId;
    }

    isolated resource function put merchantsalesummaries/[int id](MerchantSaleSummaryUpdate value) returns MerchantSaleSummary|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MERCHANT_SALE_SUMMARY);
        }
        _ = check sqlClient.runUpdateQuery(id, value);
        return self->/merchantsalesummaries/[id].get();
    }

    isolated resource function delete merchantsalesummaries/[int id]() returns MerchantSaleSummary|persist:Error {
        MerchantSaleSummary result = check self->/merchantsalesummaries/[id].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(MERCHANT_SALE_SUMMARY);
        }
        _ = check sqlClient.runDeleteQuery(id);
        return result;
    }

    remote isolated function queryNativeSQL(sql:ParameterizedQuery sqlQuery, typedesc<record {}> rowType = <>) returns stream<rowType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor"
    } external;

    remote isolated function executeNativeSQL(sql:ParameterizedQuery sqlQuery) returns psql:ExecutionResult|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor"
    } external;

    public isolated function close() returns persist:Error? {
        error? result = self.dbClient.close();
        if result is error {
            return <persist:Error>error(result.message());
        }
        return result;
    }
}

