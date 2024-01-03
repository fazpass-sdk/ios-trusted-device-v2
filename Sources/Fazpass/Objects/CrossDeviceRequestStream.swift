
public class CrossDeviceRequestStream {
    
    private var callback: ((CrossDeviceRequest) -> Void)? = nil
    
    internal init() {}
    
    internal func send(crossDeviceRequest: CrossDeviceRequest) {
        guard callback != nil else {
            return
        }
        callback!(crossDeviceRequest)
    }
    
    public func listen(callback: @escaping (CrossDeviceRequest) -> Void) {
        self.callback = callback
    }
    
    public func close() {
        self.callback = nil
    }
}
