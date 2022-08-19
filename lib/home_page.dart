import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;


class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with StripePaymentPrivate{


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: MaterialButton(
              color: Colors.red,
                onPressed: () async {

                  await _makePayment(context);

                },child: const Text("Pay")),
          )
        ],
      ),
    );
  }



}

class StripePaymentPrivate {

  Map<String,dynamic>? paymentIntentData;


  Future<void> _makePayment(BuildContext context) async {
    paymentIntentData = await _createPaymentIntent(amount: "7",currency: "USD");


    await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentIntentData!['client_secret'],
            customerId: paymentIntentData!['customer'],
            customerEphemeralKeySecret: paymentIntentData!['ephemeralKey'],
            googlePay: const PaymentSheetGooglePay(merchantCountryCode: "+20",testEnv: true),
            applePay: const PaymentSheetApplePay(merchantCountryCode: "+20",) ,
            style: ThemeMode.dark ,
            merchantDisplayName: "Mohamed"
        ));

    await _displayPaymentSheet(context:context);

  }

  _displayPaymentSheet({required BuildContext context})  async {
    try{
      await Stripe.instance.presentPaymentSheet(
          parameters: PresentPaymentSheetParameters(
              clientSecret: paymentIntentData!['client_secret'] ,
              confirmPayment: true
          )
      );
        paymentIntentData = null;


    } on StripeException catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${e.error.message}") ));

    }
  }

  Future<Map<String,dynamic>?> _createPaymentIntent({ required String amount , required String currency }) async {
    const String secretKey = "sk_test_51LXkxEEBumJR8Vl7QDF7cStRyrV3qR2QMHwZVwyIWcpkNX29eNrGyl8FebUV8eMq8xCOkTPeJ4BkQajtdvGsDJ7a00gtVU2bW2";

    final Map<String,String> headers = <String,String>{
      "Authorization":"Bearer $secretKey" ,
      "Content-Type": "application/x-www-form-urlencoded"
    };

    final Map<String , String> body = <String , String>{
      "amount": _calculateAmount(amount) ,
      "currency": currency ,
      "payment_method_types[]": "card"
    };

    final http.Response response = await http.post(Uri.parse("https://api.stripe.com/v1/payment_intents"),
        headers: headers , body: body
    );

    return await jsonDecode(response.body);

  }

  String _calculateAmount(String amount) {
    final calculate = (int.parse(amount)) * 100;
    return calculate.toString();
  }
}