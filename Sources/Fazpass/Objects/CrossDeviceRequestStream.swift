
public class CrossDeviceRequestStream {
    
    var callback: ((CrossDeviceRequest) -> Void)? = nil
    
    internal init() {}
    
    func send(crossDeviceRequest: CrossDeviceRequest) {
        guard callback != nil else {
            return
        }
        callback!(crossDeviceRequest)
    }
    
    func listen(callback: @escaping (CrossDeviceRequest) -> Void) {
        self.callback = callback
    }
    
    func close() {
        self.callback = nil
    }
}
