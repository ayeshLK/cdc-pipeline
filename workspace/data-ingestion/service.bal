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
    }
);

service cdc:Service on dbListener {

    isolated remote function onCreate(record {} entry, string tableName) returns error? {
        log:printDebug("Db insert received", dbTable = tableName);
        check produceMessage(tableName, entry);
    }

    isolated remote function onUpdate(record {} before, record {} after, string tableName) returns error? {
        log:printDebug("Db update received", dbTable = tableName);
        check produceMessage(tableName, after);
    }
}
