import Foundation
import Starscream

public class WebSocketNetworking: NSObject, WebSocketDelegate {
    
    private static var _sharedInstance: WebSocketNetworking?
    public struct WebSocketData {
        let webSocketScheme: String
        let webSocketBaseURL: String
        let tokenItem: String
        let requesTypeSubscription: String
        let accessToken: String
        
        public init(webSocketScheme: String, webSocketBaseURL: String, tokenItem: String, requesTypeSubscription: String,accessToken: String) {
            self.webSocketScheme = webSocketScheme
            self.webSocketBaseURL = webSocketBaseURL
            self.tokenItem = tokenItem
            self.requesTypeSubscription = requesTypeSubscription
            self.accessToken = accessToken
        }
    }
    
    var socket: WebSocket?
    public var connected: Bool?
    
    let webSocketConstants: WebSocketData
    let symbols: [String]
    public var connectionCompleted: ()->()? = {}
    public var receivedStringCallback: ((String)->())?
    
    public class func setup(webSocketData: WebSocketData, symbols: [String]) {
        _sharedInstance = WebSocketNetworking(webSocketConstants: webSocketData, symbols: symbols)
    }
    
    public class var sharedInstance: WebSocketNetworking {
        if  _sharedInstance == nil {
            print("Shared called before setup")
            fatalError()
        }
        
        return _sharedInstance!
    }
    
    init(webSocketConstants: WebSocketData, symbols: [String]) {
        self.webSocketConstants = webSocketConstants
        self.symbols = symbols
    }
    
}

// MARK: - Connection

extension WebSocketNetworking {
    public func connectToSocket() {
        if let url = generateConnectionURL(),
            let urlRequest = generateURLRequest(url) {
            socket = WebSocket(request: urlRequest)
            socket?.delegate = self
            socket?.connect()
        }
    }
    
    public func disconnect() {
        socket?.disconnect()
    }
    
    // MARK: - URL generation
    
    private func generateConnectionURL() -> URL? {
        var urlComponents = URLComponents()
        
        urlComponents.scheme = webSocketConstants.webSocketScheme
        urlComponents.host = webSocketConstants.webSocketBaseURL
        urlComponents.queryItems = [URLQueryItem(name: webSocketConstants.tokenItem, value: webSocketConstants.accessToken)]
        
        return urlComponents.url
    }
    
    private func generateURLRequest(_ url: URL?) -> URLRequest? {
        if let url = url {
            var request = URLRequest(url: url)
            request.timeoutInterval = 5
            
            return request
        } else {
            return nil
        }
    }
}


// MARK: - WebSocket delegate methods

extension WebSocketNetworking {
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            connected = true
            print("WebSocket is connected: \(headers)")
            handleConnectedEvent()
        case .disconnected(let reason, let code):
            connected = false
            reConnect()
            print("WebSocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            if string.contains("ping") {
                //
            } else {
                handleReceivedString(string)
            }
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            reConnect()
            break
        case .cancelled:
            connected = false
        case .error(let error):
            connected = false
            handleErrorEvent(error)
        }
    }
    
    // MARK: - Event handlers
    
    private func handleConnectedEvent() {
        connectionCompleted()
    }
    
    private func handleErrorEvent(_ error: Error?) {
        
    }
    
    private func handleReceivedString(_ string: String) {
        receivedStringCallback?(string)
    }
    
    private func reConnect() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.connectToSocket()
        }
    }
    
}

// MARK: - Subscription

extension WebSocketNetworking {
    public func subscribeToStocks(_ request: String) {
        socket?.write(string: request, completion: nil)
    }
}
