import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlutterSwishPayment {
  final String swishEndPoint;
  final String swishPassWord;
  final String pathToCert;
  final String pathToKey;
  static const MethodChannel _channel =
      const MethodChannel('flutter_swish_payment');

  FlutterSwishPayment({
    this.swishEndPoint = 'https://mss.cpc.getswish.net/swish-cpcapi/api/v1',
    this.swishPassWord = 'swish',
    @required this.pathToCert,
    @required this.pathToKey,
  });

  ///[This method returns true/false whether swish app is installed on the phone or not]
  Future<bool> isSwishInstalled() async {
    final bool _isSwishInstalled =
        await _channel.invokeMethod('isSwishAppInstalled');
    return _isSwishInstalled;
  }

  ///[Makes a request to swish api and gets the token to open the swish app from app]
  Future<String> getToken(SwishPay swishPay) async {
    final _cert = await rootBundle.load(pathToCert);
    final _key = await rootBundle.load(pathToKey);
    final _context = SecurityContext.defaultContext;
    _context.setTrustedCertificatesBytes(
      _cert.buffer.asUint8List(),
      password: swishPassWord,
    );
    _context.usePrivateKeyBytes(
      _key.buffer.asUint8List(),
      password: swishPassWord,
    );
    final _client = HttpClient(context: _context);
    final _jsonData = swishPay.toJson();

    final _req = await _client.openUrl(
      'POST',
      Uri.parse(swishEndPoint + '/paymentrequests'),
    );

    _req.headers.set(HttpHeaders.contentTypeHeader, 'APPLICATION/JSON');
    _req.write(json.encode(_jsonData));
    final _response = await _req.close();
    print('u got here');
    print(_response.toString());
    final _token = _response.headers.value('paymentrequesttoken');
    if (_response.statusCode != 201) {
      throw ArgumentError();
    }
    print(_response.statusCode);
    return '_token';
  }

  Future<bool> payWithSwish({
    @required String token,
    @required SwishPay swishPay,
  }) async {
    final _hasOpened =
        await _channel.invokeMethod('openSwishApp', <String, dynamic>{
      'token': token,
      "callBackUrl": swishPay.callbackUrl,
    });
    return _hasOpened;
  }
}

class SwishPay {
  //Declaring and initializing the most vital variables through the constructor
  //These variables are crucial to creating a swish payment object

  ///Payment reference supplied by the Merchant.
  ///This is not used by Swish but is included in responses back to the client.
  ///[This reference could for example be an order id or similar.]
  final String payeePaymentReference;

  ///[This is the url swish servers will update you on the status of the transaction]
  ///[Swish sends an HTTP POST request containing the payment request object to this url]
  ///[PAID - The payment was successful]
  ///[DECLINED - The payer declined to make the payment]
  ///[ERROR - Some error occurred, like the payment was blocked, payment request timed out etc]
  ///[CANCELLED – The payment request was cancelled either by the merchant or by the payer via the merchant site.]
  final String callbackUrl;

  ///[The Swish number of the payee. ie The one receiving the payments]
  ///It needs to match with Merchant Swish number.
  final String payeeAlias;

  ///[Total money that the payer needs to pay to the payee has to be specified]
  ///[Amount has to be greater than 1 SEK]
  final String amount;

  ///[Since it's swish, the currency is SEK and that's the only currency supported]
  final String currency;

  ///[The message truly identifies the transaction. If it's about shopping, this can be the item purchased.]
  final String message;

  SwishPay({
    @required this.payeePaymentReference,
    @required this.payeeAlias,
    @required this.message,
    @required this.callbackUrl,
    @required this.amount,
    this.currency = 'SEK',
  });

  Map<String, dynamic> toJson() => {
        'payeePaymentReference': payeePaymentReference,
        'callbackUrl': callbackUrl,
        'payeeAlias': payeeAlias,
        'amount': amount,
        'currency': currency,
        'message': message,
      };
}
