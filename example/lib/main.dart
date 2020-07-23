import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_swish_payment/flutter_swish_payment.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SwishPage(),
    );
  }
}

class SwishPage extends StatefulWidget {
  @override
  _SwishPageState createState() => _SwishPageState();
}

class _SwishPageState extends State<SwishPage> with WidgetsBindingObserver {
  AppLifecycleState _appState;
  bool _isLoading = false;
  String _error = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appState = state;
    });

    if (state == AppLifecycleState.resumed) {
      //check whether swish was the option chose
      //check whether swish app is installed again
      //TODO:Make a get request to get the details of the payment
      //Whether the transaction was successful or not
      print("This is the state of the app now " + state.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Center(
            child: Text('What went wrong ?? '),
          ),
          Center(
            child: Text(_appState.toString()),
          ),
          CupertinoButton(
              child: _isLoading
                  ? CircularProgressIndicator(
                    backgroundColor: CupertinoColors.white,
                  )
                  : Text('PAY WITH SWISH'),
              color: CupertinoColors.activeBlue,
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                });
                try {
                  final _myPayment = FlutterSwishPayment(
                    pathToKey:
                        'assets/Swish_Merchant_TestCertificate_1234679304.key',
                    pathToCert:
                        'assets/Swish_Merchant_TestCertificate_1234679304.p12',
                  );
                  final _isSwishInstalled = await _myPayment.isSwishInstalled();

                  final _swishPay = SwishPay(
                    message: "Wonderful Big Burger For Mr MAthew",
                    callbackUrl:
                        "https://www.google.com",
                    amount: "1",
                    payeeAlias: "1231181189",
                    payeePaymentReference: "1239012128932378",
                  );

                  if (_isSwishInstalled) {
                    final _token = await _myPayment.getToken(_swishPay);
                    final _hasSwishOpened = await _myPayment.payWithSwish(
                      token: _token,
                      swishPay: _swishPay,
                    );

                    print("Swish has opened?? " + _hasSwishOpened.toString());
                  }
                } catch (e) {
                  setState(() {
                    _error = e.toString();
                  });

                }
                _isLoading = false;
              }),
        ],
      ),
    );
  }
}

///[SWISH PAYMENT INTEGRATION GATEWAY]
class SwishPayment {
  String payeePaymentReference;
  String callbackUrl;
  String payeeAlias;
  String amount;
  String currency;
  String message;

  SwishPayment(
    this.payeePaymentReference,
    this.callbackUrl,
    this.payeeAlias,
    this.amount,
    this.currency,
    this.message,
  );

  SwishPayment.fromJson(Map<String, dynamic> json)
      : payeePaymentReference = json['payeePaymentReference'],
        callbackUrl = json['callbackUrl'],
        payeeAlias = json['payeeAlias'],
        amount = json['amount'],
        currency = json['currency'],
        message = json['message'];

  Map<String, dynamic> toJson() => {
        'payeePaymentReference': payeePaymentReference,
        'callbackUrl': callbackUrl,
        'payeeAlias': payeeAlias,
        'amount': amount,
        'currency': currency,
        'message': message,
      };
}

class SwishService {
  // For payout requests a specific *Swish_Merchant_TestSigningCertificate*
//is provided that **must** be used to sign the payout request payload
//(create the signature property value). No other signing certificate
//will be accepted by MSS but result in error message returned to
//caller.
  static Future<String> postWithClientCertificate() async {
    final swishEndpoint = 'https://mss.cpc.getswish.net/swish-cpcapi/api/v1';
    final credential = 'swish';
    var context = SecurityContext.defaultContext;
    ByteData cert = await rootBundle
        .load('assets/Swish_Merchant_TestCertificate_1234679304.p12');
    ByteData key = await rootBundle
        .load('assets/Swish_Merchant_TestCertificate_1234679304.key');
    context.useCertificateChainBytes(cert.buffer.asUint8List(),
        password: credential);
    context.usePrivateKeyBytes(key.buffer.asUint8List(), password: credential);
    HttpClient client = HttpClient(context: context);

    var data = createSamplePayment().toJson();
    var request = await client.openUrl(
        'POST', Uri.parse(swishEndpoint + '/paymentrequests'));
    request.headers.set(HttpHeaders.contentTypeHeader, 'APPLICATION/JSON');
    request.write(json.encode(data));
    var response = await request.close();

    print(response.statusCode);
    var token = response.headers.value('paymentrequesttoken');
    print(token);
    return token;
  }

  static SwishPayment createSamplePayment() {
    return SwishPayment(
      '0123456789',
      'https://www.google.com',
      '1231181189',
      '100',
      'SEK',
      'Kingston USB Flash Drive 8 GB',
    );
  }
}
