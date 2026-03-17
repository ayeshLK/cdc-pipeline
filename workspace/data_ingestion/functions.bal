import ballerinax/cdc;

public isolated function isLive() returns boolean|error {
    return cdc:isLive(dbListener);
}
