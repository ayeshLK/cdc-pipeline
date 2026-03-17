import ballerina/log;
import ballerinax/cdc;
import ballerinax/mysql;
import ballerinax/mysql.cdc.driver as _;

listener mysql:CdcListener dbListener = new (
    database = {
        ...db,
        includedDatabases: "ecommerce_db",
        includedTables: [
            "ecommerce_db.orders",
            "ecommerce_db.order_items",
            "ecommerce_db.products"
        ]
    },
    options = {
        snapshotMode: cdc:NO_DATA,
        skippedOperations: [cdc:TRUNCATE, cdc:DELETE]
    },
    livenessInterval = 120.0
);

service cdc:Service on dbListener {

    function init() {
        log:printInfo("Service started successfully");
    }

    isolated remote function onCreate(record {} entry, string tableName) returns error? {
        log:printDebug("Db insert received", dbTable = tableName);
        check producer->send({topic: tableName, value: entry});
    }

    isolated remote function onUpdate(record {} before, record {} after, string tableName) returns error? {
        log:printDebug("Db update received", dbTable = tableName);
        check producer->send({topic: tableName, value: after});
    }
}
