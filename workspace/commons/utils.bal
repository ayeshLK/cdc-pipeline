import ballerina/log;

# Logs a message as a warning or an error depending on the presence of an error.
#
# + message - The message to be logged
# + 'error - The optional error associated with the log entry. If provided,
#         the log will be recorded as an error; otherwise, it will be recorded as a warning.
# + keyValues - Additional key values to be logged
public isolated function logWarnOrError(string message, error? 'error = (), *log:KeyValues keyValues) {
    if 'error is () {
        log:printWarn(message, keyValues = keyValues);
        return;
    }
    log:printError(message, 'error, keyValues = keyValues);    
}
