import ballerina/time;

isolated time:Utc? lastEventReceivedTime = ();

isolated function updateEventReceivedTime() {
    lock {
        lastEventReceivedTime = time:utcNow();
    }
}

isolated function getLastEventReceivedTime() returns time:Utc? {
    lock {
        return lastEventReceivedTime;
    }
}

public isolated function isLive() returns boolean|error {
    time:Utc? lastEventReceivedTime = getLastEventReceivedTime();
    if lastEventReceivedTime is () {
        return false;
    }
    if time:utcDiffSeconds(lastEventReceivedTime, time:utcNow()) > livenessInterval {
        return false;
    }
    return true;
}
