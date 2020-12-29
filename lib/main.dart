import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meditation/screens/splash.dart';
import 'package:meditation/util/color.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  InAppPurchaseConnection.enablePendingPurchases();
  await Firebase.initializeApp();
  return runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    //GlobalConfiguration().loadFromPath("asset/config/app_settings.json");
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    return MaterialApp(
        title: 'Meditatio4Soul',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primaryColor: primaryColor, fontFamily: 'Raleway'),
        home: Splash());
  }
}
