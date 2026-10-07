/// One call to Adjust for one event. A factory builds it.
public protocol AdjustEventTracker {
    func track() throws
}
