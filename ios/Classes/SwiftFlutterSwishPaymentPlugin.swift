import Flutter
import UIKit

enum StringConstants: String {
    case Host = "paymentrequest"
    case SwishUrl = "swish://"
    case Scheme = "swish"
}

public class SwiftFlutterSwishPaymentPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_swish_payment", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterSwishPaymentPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "isSwishAppInstalled" {
            let isSwishInstalled: Bool = isSwishAppInstalled()
            result(isSwishInstalled)
        }

        if call.method == "openSwishApp" {
            // Get the arguments from the call
            let args: Dictionary = call.arguments as! Dictionary<String, Any>
            // Get the token from the arguments
            let token: String = args["token"] as! String
            // Get the callback url from the arguments
            let callBackUrl: String = args["callBackUrl"] as! String

            // Pass the token to the openApp method
            result(openSwishAppWithToken(token, callBackUrl: callBackUrl))
        }
        // If a platform call is called and then none of the methods matches the ones here
        //then we will throw a nice error
        result(FlutterMethodNotImplemented)
    }

    func isSwishAppInstalled() -> Bool {
        guard let url = URL(string: StringConstants.SwishUrl.rawValue) else {
            preconditionFailure("Invalid url")
        }
        return UIApplication.shared.canOpenURL(url)
    }

    func openSwishAppWithToken(_ token: String, callBackUrl: String) -> Bool { guard isSwishAppInstalled() else {
        // Swish app is not installed, show error
        return false
    }
    var urlComponents = URLComponents()
    urlComponents.host = StringConstants.Host.rawValue
    urlComponents.scheme = StringConstants.Scheme.rawValue
    urlComponents.queryItems = [URLQueryItem(name: "token", value: token),
                                URLQueryItem(name: "callbackurl", value: callBackUrl)]
    guard let url = urlComponents.url else { preconditionFailure("Invalid url")
    }

    if #available(iOS 10.0, *) {
        UIApplication.shared.open(url, options: [:], completionHandler: { success in if !success {
        } })
    } else {
        if UIApplication.shared.canOpenURL(url) {
            print("It got here and can it open the application? " + String(UIApplication.shared.canOpenURL(url)));
            return UIApplication.shared.openURL(url)
        }else {
            return false;
        }
        
    }
    return true
    }

//    // The URL could not be opened, show error
//    func encodedCallbackUrl() -> String? {
//        let callback = StringConstants.MerchantCallbackUrl.rawValue
//        let disallowedCharacters = NSCharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]")
//        let allowedCharacters = disallowedCharacters.inverted
//        return callback.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
//    }
}
