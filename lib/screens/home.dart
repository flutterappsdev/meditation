import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:meditation/screens/details.dart';
import 'package:meditation/screens/reminder/alarm.dart';
import 'package:meditation/screens/setting.dart';
import 'package:meditation/screens/stories.dart';
import 'package:meditation/util/color.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

// import 'explore.dart';

class Home extends StatefulWidget {
  final bool isPaymentSuccess;
  final String plan;
  Home({this.isPaymentSuccess, this.plan});

  @override
  _HomeState createState() => _HomeState();
}

// Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) {
//   print(message);
// }

class _HomeState extends State<Home> with WidgetsBindingObserver {
  FirebaseMessaging firebaseMessaging = new FirebaseMessaging();

  @override
  void dispose() {
    super.dispose();
    categoryList.clear();
  }

  initState() {
    super.initState();
    _getFeaturedStories();
    _getCategories();

    // Show payment success alert.
    if (widget.isPaymentSuccess != null && widget.isPaymentSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Alert(
          context: context,
          type: AlertType.success,
          title: "Success",
          desc:
              "You've successfully subscribed to our ${widget.plan} package. To check your subscrition details goto account page under settings tab.",
          buttons: [
            DialogButton(
              child: Text(
                "Okay",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              onPressed: () => Navigator.pop(context),
              width: 120,
            )
          ],
        ).show();
      });
    }

    WidgetsBinding.instance.addObserver(this);
    firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> massage) async {
        showNotification(massage);
        print(massage);
        print("Foreground notification");
      },
      // onBackgroundMessage: myBackgroundMessageHandler,
      onLaunch: (Map<String, dynamic> massage) async {
        print(massage);
      },
      onResume: (Map<String, dynamic> massage) async {
        print(massage);
      },
    );

    // firebaseMessaging.requestNotificationPermissions(
    //   IosNotificationSettings(
    //       badge: true, alert: true, provisional: true, sound: true),
    // );
    // firebaseMessaging.onIosSettingsRegistered
    //     .listen((IosNotificationSettings settings) {});
    firebaseMessaging.getToken().then((token) {});
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid = new AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    var initializationSettingsIOS = new IOSInitializationSettings(
        // onDidReceiveLocalNotification: onDidReceiveLocalNotification
        );
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  //for Foreground notification
  Future showNotification(massage) async {
    var android = new AndroidNotificationDetails(
        'channel id', 'channel NAME', 'CHANNEL DESCRIPTION',
        priority: Priority.High, importance: Importance.Max);
    var iOS = new IOSNotificationDetails();
    // var iOS =
    //     new IOSNotificationDetails(presentAlert: true, presentBadge: true);
    var platform = new NotificationDetails(android, iOS);
    await flutterLocalNotificationsPlugin.show(
        2,
        '${massage['notification']['title']}',
        '${massage['notification']['body']}',
        platform,
        payload: '');
  }

  List featuredStoryList = [];

  _getFeaturedStories() async {
    return Firestore.instance
        .collection('fl_content')
        .where("_fl_meta_.schema", isEqualTo: "featuredStories")
        .snapshots()
        .listen((data) async {
      featuredStoryList =
          []; // Empty the array if database changes. Otherwise multiple stories will be made.
      Map fetchedObj;
      for (var doc in data.docs) {
        fetchedObj = doc.data();
        String coverImage =
            await doc['coverImage'][0].get().then((documentSnapshot) {
          return documentSnapshot.data['file'];
        });
        fetchedObj['coverImage'] = coverImage;
        featuredStoryList.add(fetchedObj);
      }
      if (mounted) setState(() {});
      return featuredStoryList;
    });
  }

  List categoryList = [];

  _getCategories() async {
    return Firestore.instance
        .collection('fl_content')
        .where("_fl_meta_.schema", isEqualTo: "categories")
        .snapshots()
        .listen((data) async {
      categoryList.clear();
      Map fetchedObj;
      for (var doc in data.docs) {
        fetchedObj = doc.data();

        String coverImage =
            await doc['coverImage'][0].get().then((documentSnapshot) {
          return documentSnapshot.data['file'];
        });
        fetchedObj['coverImage'] = coverImage;
        categoryList.add(fetchedObj);
      }
      if (mounted) setState(() {});
      return categoryList;
    });
  }

  int _selectedIndex = 0;

  List<Widget> pages = [];
  appBarWidget() {
    return Positioned(
      top: -10,
      height: 270,
      width: MediaQuery.of(context).size.width,
      child: Container(
        color: primaryColor,
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[]),
        ),
      ),
    );
  }

  buildWidget() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.02,
      width: MediaQuery.of(context).size.width,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Center(
              child: Image.asset(
                'asset/img/logoWhite.png',
                height: 150,
                width: 190,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            buildGuidedMeditation(),
            SizedBox(height: 30),
            featuredStoryList.length > 0 ? buildmeditationStep() : Container(),
            SizedBox(height: 30),
            buildCategories(),
          ]),
    );
  }

  buildGuidedMeditation() {
    return Container(
      // height: MediaQuery.of(context).size.height * .28
      height: 200,
      width: MediaQuery.of(context).size.width - 40,
      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
      decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('asset/img/bg/guideMeditation.jpg'),
              alignment: Alignment.centerRight,
              fit: BoxFit.cover),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(12, 12, 12, .3),
              blurRadius: 10,
              offset: Offset(0, 10),
            )
          ]),
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 10, 130, 10),
        child: Column(
          children: <Widget>[
            Text('Guided meditation for Beginners',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textColor)),
            SizedBox(
              height: 15,
            ),
            Text('Most Volunteers had continued practicing regular',
                style: TextStyle(fontSize: 16, color: textColor))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget _page1 = SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height +
              120 * (categoryList.length / 2).round().toDouble(),
          // height: MediaQuery.of(context).size.height + 190,
          child: Stack(children: <Widget>[
            appBarWidget(),
            buildWidget(),
          ]),
        ));
    Widget _progress = Alarm();
    // Widget _explore = Explore();
    Widget _setting = Setting();
    pages = [_page1, _progress, _setting];
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            pages.elementAt(_selectedIndex),
            Align(
              alignment: Alignment.bottomCenter,
              child: buildBottomNavigationBar(),
            )
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Exit'),
          content: Text('Do you want to exit the app?'),
          actions: <Widget>[
            FlatButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No'),
            ),
            FlatButton(
              onPressed: () =>
                  SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  CurvedNavigationBar buildBottomNavigationBar() {
    return CurvedNavigationBar(
        height: 60.0,
        color: primaryColor,
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: primaryColor,
        items: [
          Icon(Icons.home, color: iconColor),
          Icon(Icons.alarm, color: iconColor),
          // Icon(Icons.explore, color: iconColor),
          Icon(Icons.settings, color: iconColor),
        ],
        onTap: (int index) {
          setState(() => _selectedIndex = index);
        });
  }

  Widget buildCategories() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text("Categories",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const Text("What is your priority right now?",
              style: TextStyle(fontSize: 12)),
          StreamBuilder(
            stream: Firestore.instance
                .collection('fl_content')
                .where("_fl_meta_.schema", isEqualTo: "categories")
                .getDocuments()
                .asStream(),
            builder: (BuildContext context,
                AsyncSnapshot<QuerySnapshot> fetchedObject) {
              if (fetchedObject.hasData) {
                return GridView.builder(
                    shrinkWrap: true,
                    physics: BouncingScrollPhysics(),
                    itemCount: fetchedObject.data.documents.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        childAspectRatio: 1.5, crossAxisCount: 2),
                    itemBuilder: (BuildContext context, int index) {
                      DocumentSnapshot data =
                          fetchedObject.data.documents[index];
                      var cl;
                      categoryList.forEach((element) {
                        if (element['name'] == data['name']) {
                          cl = element;
                        }
                      });

                      return cl != null
                          ? GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(new PageRouteBuilder(
                                    pageBuilder: (BuildContext context, _, __) {
                                  return Details(
                                      id: data['id'],
                                      coverImage: cl['coverImage'],
                                      name: data['name']);
                                }, transitionsBuilder: (_,
                                        Animation<double> animation,
                                        __,
                                        Widget child) {
                                  return new FadeTransition(
                                      opacity: animation, child: child);
                                }));
                              },
                              child: Hero(
                                tag: data['id'],
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    image: DecorationImage(
                                        alignment: Alignment.center,
                                        fit: BoxFit.cover,
                                        image: NetworkImage(
                                          "https://firebasestorage.googleapis.com/v0/b/${GlobalConfiguration().getString("firebaseProjectID")}.appspot.com/o/flamelink%2Fmedia%2F${cl['coverImage']}?alt=media",
                                        )),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.only(
                                      top: 20, left: 10, right: 10),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 6),
                                  child: Text(
                                    data['name'],
                                    style: TextStyle(
                                        decoration: TextDecoration.none,
                                        color: textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: SizedBox(
                                height: 100.0,
                                child: Shimmer.fromColors(
                                  baseColor: primaryColor,
                                  highlightColor: darkPrimaryColor,
                                  child: Center(
                                    child: Container(),
                                  ),
                                ),
                              ),
                            );
                    });
              } else
                return Center(
                  child: SizedBox(
                    height: 100.0,
                    child: Shimmer.fromColors(
                      baseColor: primaryColor,
                      highlightColor: darkPrimaryColor,
                      child: Center(
                        child: Container(),
                      ),
                    ),
                  ),
                );
            },
          ),
        ],
      ),
    );
  }

  Widget buildmeditationStep() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(left: 20, bottom: 20),
            child: Text("Featured stories",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ),
          Container(
            height: 100,
            padding: EdgeInsets.only(left: 10.0),
            child: featuredStoryList.length > 0
                ? ListView(
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    children: featuredStoryList.map((dynamic fsl) {
                      return GestureDetector(
                          child: Container(
                              height: 90,
                              width: 162,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.only(top: 15, left: 20),
                              child: Text(fsl['name'],
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  image: DecorationImage(
                                      image: NetworkImage(
                                        "https://firebasestorage.googleapis.com/v0/b/${GlobalConfiguration().getString("firebaseProjectID")}.appspot.com/o/flamelink%2Fmedia%2F${fsl['coverImage']}?alt=media",
                                      ),
                                      alignment: Alignment.centerRight,
                                      fit: BoxFit.cover),
                                  borderRadius: BorderRadius.circular(10))),
                          onTap: () {
                            Navigator.push(
                                context,
                                CupertinoPageRoute(
                                    builder: (context) =>
                                        Stories(fsl['storyItems'])));
                            // Navigator.of(context).push(new PageRouteBuilder(
                            //     pageBuilder: (BuildContext context, _, __) {
                            //   return Stories(fsl['storyItems']);
                            // }, transitionsBuilder: (_,
                            //         Animation<double> animation,
                            //         __,
                            //         Widget child) {
                            //   return new FadeTransition(
                            //       opacity: animation, child: child);
                            // }));
                          });
                    }).toList())
                : SizedBox(
                    height: 100.0,
                    child: Shimmer.fromColors(
                      baseColor: Colors.white,
                      highlightColor: darkPrimaryColor,
                      child: Center(
                        child: Image.asset(
                          'asset/img/logo-with-text.png',
                          height: 100.0,
                        ),
                      ),
                    ),
                  ),
          )
        ],
      ),
    );
  }
}
