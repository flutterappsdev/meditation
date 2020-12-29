import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase/store_kit_wrappers.dart';
import 'package:meditation/screens/home.dart';
import 'package:meditation/util/color.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:url_launcher/url_launcher.dart';

class Subscription extends StatefulWidget {
  final bool isPaymentSuccess;
  Subscription({this.isPaymentSuccess});

  @override
  _SubscriptionState createState() => _SubscriptionState();
}

class _SubscriptionState extends State<Subscription> {
  InAppPurchaseConnection _iap = InAppPurchaseConnection.instance;
//TODO: replace with product ids
  String id1 = 'month_1';
  String id2 = 'month_6';
  String id3 = 'year_1'; 

  /// if the api is available or not.
  bool isAvailable = true;

  /// products for sale
  List<ProductDetails> products = [];

  /// Past purchases
  List<PurchaseDetails> purchases = [];

  /// Update to purchases
  StreamSubscription _streamSubscription;
  ProductDetails selectedPlan;
  ProductDetails selectedProduct;
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  // UrlLauncher launcher = UrlLauncher();
  @override
  void initState() {
    super.initState();
    _initialize();
    // Show payment failure alert.
    if (widget.isPaymentSuccess != null && !widget.isPaymentSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Alert(
          context: context,
          type: AlertType.error,
          title: "Failed",
          desc: "Oops!! something went wrong. Please try again",
          buttons: [
            DialogButton(
              child: Text(
                "Try again",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              onPressed: () => Navigator.pop(context),
              width: 120,
            )
          ],
        ).show();
      });
    }
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  void _initialize() async {
    isAvailable = await _iap.isAvailable();
    if (isAvailable) {
      List<Future> futures = [_getProducts(), _getpastPurchases()];
      await Future.wait(futures);

      /// removing all the pending puchases.
      if (Platform.isIOS) {
        var paymentWrapper = SKPaymentQueueWrapper();
        var transactions = await paymentWrapper.transactions();
        transactions.forEach((transaction) async {
          print(transaction.transactionState);
          await paymentWrapper
              .finishTransaction(transaction)
              .catchError((onError) {
            print('finishTransaction Error $onError');
          });
        });
      }

      _streamSubscription = _iap.purchaseUpdatedStream.listen((data) {
        setState(
          () {
            print("objec===============t");
            purchases.addAll(data);

            purchases.forEach(
              (purchase) async {
                await _verifyPuchase(purchase.productID);
              },
            );
          },
        );
      });
      _streamSubscription.onError(
        (error) {
          _scaffoldKey.currentState.showSnackBar(
            SnackBar(
              content: error != null
                  ? Text('$error')
                  : Text("Oops!! something went wrong. Please try again"),
            ),
          );
        },
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      foregroundDecoration: BoxDecoration(),
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
          image: DecorationImage(
              colorFilter: ColorFilter.mode(
                  primaryColor.withOpacity(.7), BlendMode.darken),
              alignment: Alignment.center,
              fit: BoxFit.cover,
              image: AssetImage('asset/img/bg/guideMeditation.jpg'))),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <
            Widget>[
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              color: Colors.white,
              icon: Icon(
                Icons.cancel,
                size: 30,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              ListBody(
                mainAxis: Axis.vertical,
                children: <Widget>[
                  ListTile(
                    dense: true,
                    title: Text(
                      "Subscribe Now",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 35,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.star,
                      color: Colors.white,
                    ),
                    title: Text(
                      "Lock and unlock contant for free users",
                      style: TextStyle(
                          color: Colors.white,
                          // Color(0xFF1A1A1A),
                          fontSize: 16,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.star,
                      color: Colors.white,
                    ),
                    title: Text(
                      "Create custom packages",
                      style: TextStyle(
                          color: Colors.white,
                          // Color(0xFF1A1A1A),
                          fontSize: 16,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.star,
                      color: Colors.white,
                    ),
                    title: Text(
                      "Package summary details",
                      style: TextStyle(
                          color: Colors.white,
                          // Color(0xFF1A1A1A),
                          fontSize: 16,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.star,
                      color: Colors.white,
                    ),
                    title: Text(
                      "In app purchase",
                      style: TextStyle(
                          color: Colors.white,
                          // Color(0xFF1A1A1A),
                          fontSize: 16,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                  ),
                ],
              ),
              Container(
                width: MediaQuery.of(context).size.width * .99,
                height: MediaQuery.of(context).size.height * .18,

                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            valueColor: new AlwaysStoppedAnimation<Color>(
                                primaryColor)),
                      )
                    : products.length > 0
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: products.map((product) {
                              return productList(
                                context: context,
                                product: product,
                                interval: getInterval(product),
                                intervalCount: product
                                    .skProduct.subscriptionPeriod.numberOfUnits
                                    .toString(),
                                price: product.price,
                                onTap: () {
                                  setState(() {
                                    selectedProduct = product;
                                  });
                                },
                              );
                            }).toList())
                        : Center(child: Text("No product found!!")),
                // ),
              ),
              SizedBox(
                height: 25,
              ),
              Container(
                height: 60,
                width: 250,
                child: InkWell(
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    child: Center(
                        child: Text(
                      "CONTINUE",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )),
                  ),
                  onTap: () {
                    if (selectedProduct != null) {
                      _buyProduct(selectedProduct);
                    } else {
                      print("please select");
                    }
                  },
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Platform.isIOS
                  ? Container(
                      height: 60,
                      width: 250,
                      child: InkWell(
                        child: Card(
                            color: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                            child: Center(
                                child: Text(
                              "RESTORE PURCHASE",
                              style: TextStyle(
                                  fontSize: 15,
                                  color: textColor,
                                  fontWeight: FontWeight.bold),
                            ))),
                        onTap: () async {
                          var result = await _getpastPurchases();
                          if (result.length == 0) {
                            showDialog(
                                context: context,
                                builder: (ctx) {
                                  return AlertDialog(
                                    content: Text("No purchase found"),
                                    title: Text("Past Purchases"),
                                  );
                                });
                          }
                        },
                      ))
                  : Container(),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  InkWell(
                    onTap: () => _launchURL(
                      'https://www.help.deligence.com/',
                    ),
                    child: Text("Terms & Conditions ",
                        style: TextStyle(color: Colors.white)),
                  ),
                  InkWell(
                    onTap: () => _launchURL(
                      'https://www.help.deligence.com/',
                    ),
                    child: Text("Privacy Policy ",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  """Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum comes from sections 1.10.32 and 1.10.33 of "de Finibus Bonorum et Malorum" (The Extremes of Good and Evil) by Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. The first line of Lorem Ipsum, "Lorem ipsum dolor sit amet..", comes from a line in section 1.10.32.""",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ]),
      ),
    ));
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  InkWell productList({
    BuildContext context,
    String intervalCount,
    String interval,
    Function onTap,
    ProductDetails product,
    String price,
  }) {
    return InkWell(
      child: ClipRect(
        child: AnimatedContainer(
          curve: Curves.linear,
          height: selectedProduct != product
              ? 90
              : 135, //setting up dimention if product get selected
          width: selectedProduct !=
                  product //setting up dimention if product get selected
              ? MediaQuery.of(context).size.width * .25
              : MediaQuery.of(context).size.width * .29,
          decoration: selectedProduct == product
              ? BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  border: Border.all(width: 5, color: Colors.yellow))
              : null,
          duration: Duration(milliseconds: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height * .02),
              Text(intervalCount,
                  style: TextStyle(
                      color: selectedProduct !=
                              product //setting up color if product get selected
                          ? Colors.white
                          : Colors.black,
                      fontSize: 25,
                      fontWeight: FontWeight.bold)),
              Text(interval,
                  style: TextStyle(
                      color: selectedProduct !=
                              product //setting up color if product get selected
                          ? Colors.white
                          : Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              Text(price,
                  style: TextStyle(
                      color: selectedProduct !=
                              product //setting up product if product get selected
                          ? Colors.white
                          : Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
            //      )),
          ),
        ),
      ),
      onTap: onTap,
    );
  }

  ///fetch products
  Future<void> _getProducts() async {
    Set<String> ids = Set.from([id1, id2, id3]);
    ProductDetailsResponse response = await _iap.queryProductDetails(ids);
    setState(() {
      products = response.productDetails;
      print("response.productDetails ${response.productDetails.length}");
    });

    //initial selected of products
    if (response.productDetails.length > 2) {
      print(products[2].description);
      selectedProduct = products[2];
    }
  }

  ///get past purchases of user
  Future _getpastPurchases() async {
    QueryPurchaseDetailsResponse response = await _iap.queryPastPurchases();
    for (PurchaseDetails purchase in response.pastPurchases) {
      if (Platform.isIOS) {
        _iap.completePurchase(purchase);
      }
    }
    setState(() {
      purchases = response.pastPurchases;
    });
    if (purchases.length > 0) {
      purchases.forEach(
        (purchase) async {
          print('Plan    ${purchase.productID}');
          await _verifyPuchase(purchase.productID);
        },
      );
    } else {
      return purchases;
    }
  }

  /// check if user has pruchased
  PurchaseDetails _hasPurchased(String productId) {
    return purchases.firstWhere((purchase) => purchase.productID == productId,
        orElse: () => null);
  }

  ///verifying opurhcase of user
  Future<void> _verifyPuchase(String id) async {
    PurchaseDetails purchase = _hasPurchased(id);
    print("purchase");

    print(purchase);
    if (purchase != null && purchase.status == PurchaseStatus.purchased) {
      print(purchase.productID);
      if (Platform.isIOS) {
        await _iap.completePurchase(purchase);
      }
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (context) {
          return Home(
            isPaymentSuccess: true,
            plan: "${purchase.productID}",
          );
        }),
      );
    } else if (purchase != null && purchase.status == PurchaseStatus.error) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
            builder: (context) => Subscription(isPaymentSuccess: false)),
      );
    }
    return;
  }

  ///buying a product
  void _buyProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  String getInterval(ProductDetails product) {
    SKSubscriptionPeriodUnit periodUnit =
        product.skProduct.subscriptionPeriod.unit;
    if (SKSubscriptionPeriodUnit.month == periodUnit) {
      return "Month(s)";
    } else if (SKSubscriptionPeriodUnit.week == periodUnit) {
      return "Week(s)";
    } else {
      return "Year";
    }
  }
}
