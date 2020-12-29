import 'dart:io';
import 'package:apple_sign_in/apple_sign_in.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:meditation/models/custom_web_view.dart';
import 'package:meditation/screens/auth/forgetPassword.dart';
import 'package:meditation/screens/auth/signup.dart';
import 'package:meditation/screens/auth/twitterLogin.dart';
import 'package:meditation/screens/home.dart';
import 'package:meditation/util/animation.dart';
import 'package:meditation/util/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginData {
  String email = '';
  String password = '';
}

class _LoginState extends State<Login> {
  bool appleLogin = false;
  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      //check for ios if developing for both android & ios
      setState(() {});
      appleLogin = true;
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  _LoginData _data = new _LoginData();

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: <Widget>[
            backgroundImageWidget(),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 50, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  FadeAnimation(
                      1.5,
                      Text(
                        "Login",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 30),
                      )),
                  SizedBox(
                    height: 30,
                  ),
                  FadeAnimation(
                      1.7,
                      Center(
                        child:
                            Image.asset('asset/img/logoWhite.png', height: 150),
                      )),
                  loginFormWidget(),
                  SizedBox(
                    height: 20,
                  ),
                  FadeAnimation(
                      1.9,
                      const Text(
                        "or connect with",
                        style: TextStyle(fontSize: 14),
                      )),
                  SizedBox(
                    height: 10,
                  ),
                  socialLoginWidget(),
                  const SizedBox(
                    height: 15,
                  ),
                  if (appleLogin) Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: AppleSignInButton(
                            //style: ButtonStyle.black,
                            type: ButtonType.continueButton,
                            onPressed: () async {
                              final FirebaseUser currentUser =
                                  await handleAppleLogin()
                                      .catchError((onError) {
                                //show snackbar
                              });
                              if (currentUser != null) {
                                print(
                                    'usernaem ${currentUser.displayName} \n photourl ${currentUser.photoUrl}');
                                await _setDataUser(currentUser);
                                await Navigator.pushReplacement(
                                    context,
                                    CupertinoPageRoute(
                                        builder: (context) => Home()));
                              }
                            },
                          ),
                        ) else Container(),
                  signupButtonWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Displaying background image and logo
  Widget backgroundImageWidget() {
    return Positioned(
        top: -40,
        height: 400,
        width: MediaQuery.of(context).size.width,
        child: Container(
          decoration: BoxDecoration(color: primaryColor),
        ));
  }

  ///apple login
  Future<FirebaseUser> handleAppleLogin() async {
    FirebaseUser user;
    if (await AppleSignIn.isAvailable()) {
      try {
        final AuthorizationResult result = await AppleSignIn.performRequests([
          AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
        ]).catchError((onError) {
          print("inside $onError");
        });

        switch (result.status) {
          case AuthorizationStatus.authorized:
            try {
              final AppleIdCredential appleIdCredential = result.credential;

              OAuthProvider oAuthProvider =  OAuthProvider("apple.com");
              final AuthCredential credential = oAuthProvider.getCredential(
                idToken: String.fromCharCodes(appleIdCredential.identityToken),
                accessToken:
                    String.fromCharCodes(appleIdCredential.authorizationCode),
              );

              user = (await _auth.signInWithCredential(credential)).user;
            } catch (e) {
              print("error");
            }
            break;
          case AuthorizationStatus.error:
            // do something

            _scaffoldKey.currentState.showSnackBar(SnackBar(
              content: Text('An error has occurred. Try Again.'),
              duration: Duration(seconds: 8),
            ));

            break;

          case AuthorizationStatus.cancelled:
            break;
        }
      } catch (error) {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('$error.'),
          duration: Duration(seconds: 8),
        ));
      }
    } else {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Apple connection is not available for your device'),
        duration: Duration(seconds: 8),
      ));
    }
    return user;
  }

  /// login form
  Widget loginFormWidget() {
    return FadeAnimation(
        1.7,
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(196, 135, 198, .3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                )
              ]),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  FadeAnimation(
                      1.8,
                      Container(
                        width: MediaQuery.of(context).size.width - 100,
                        child: Text(
                          "Login",
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 24),
                        ),
                      )),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    height: 55.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.0),
                        border: Border.all(color: splashIndicatorColor)),
                    child: TextFormField(
                      style: TextStyle(fontWeight: FontWeight.w600),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "Email",
                        hintStyle: TextStyle(
                            fontSize: 15,
                            color: splashIndicatorColor.withOpacity(0.8)),
                        icon: Icon(Icons.email),
                        border: InputBorder.none,
                      ),
                      onSaved: (String value) {
                        this._data.email = value;
                      },
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Email address required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    height: 55.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.0),
                        border: Border.all(color: splashIndicatorColor)),
                    child: TextFormField(
                      obscureText: true,
                      style: TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                          hintText: "Password",
                          hintStyle: TextStyle(
                            fontSize: 15,
                            color: splashIndicatorColor.withOpacity(0.8),
                          ),
                          icon: Icon(Icons.lock),
                          border: InputBorder.none),
                      onSaved: (String value) {
                        this._data.password = value;
                      },
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Password required';
                        }
                        return null;
                      },
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final showSnackBar = await Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (context) => ForgetPassword()));
                      if (showSnackBar != null && showSnackBar == true) {
                        _scaffoldKey.currentState.showSnackBar(SnackBar(
                          content: Text(
                              'Follow the link sent to your email address to reset the password.'),
                          duration: Duration(seconds: 8),
                        ));
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Center(
                          child: Text(
                        "Forgot your password?",
                        style: TextStyle(
                          color: primaryColor,
                        ),
                      )),
                    ),
                  ),
                  FadeAnimation(
                      1.8,
                      FloatingActionButton(
                        backgroundColor: primaryColor,
                        onPressed: () async {
                          if (_formKey.currentState.validate()) {
                            _formKey.currentState.save();
                            await _handleSignIn(_data);
                            Navigator.pushReplacement(
                                context,
                                CupertinoPageRoute(
                                    builder: (context) => Home()));
                          }
                        },
                        child: Icon(Icons.arrow_forward),
                      )),
                ],
              ),
            ),
          ),
        ));
  }

  ///Login Button Navigate to Home screen
  Widget loginButtonWidget() {
    return Positioned(
      height: 200,
      width: MediaQuery.of(context).size.width + 20,
      child: FadeAnimation(
        1.9,
        Container(
          child: InkWell(
            onTap: () {
              Navigator.push(
                  context, CupertinoPageRoute(builder: (context) => Home()));
            },
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: primaryColor,
              ),
              child: Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  /// Social login button like Facebook, Twitter, Google
  Widget socialLoginWidget() {
    return FadeAnimation(
      1.9,
      Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            InkWell(
              child: Material(
                child: SvgPicture.asset(
                  'asset/img/social-icon/google.svg',
                  semanticsLabel: 'Acme Logo',
                  height: 35,
                  width: 35,
                ),
              ),
              onTap: () async {
                final FirebaseUser currentUser = await _handleGoogleSignIn();
                print(currentUser);
                if (currentUser != null) {
                  await _setDataUser(currentUser);
                  await Navigator.push(context,
                      CupertinoPageRoute(builder: (context) => Home()));
                }
              },
            ),
            SizedBox(width: 20),
            InkWell(
              child: Material(
                child: SvgPicture.asset(
                  'asset/img/social-icon/facebook.svg',
                  semanticsLabel: 'Acme Logo',
                  height: 35,
                  width: 35,
                ),
              ),
              onTap: () async {
                final FirebaseUser currentUser = await handleFacebookLogin();

                if (currentUser != null) {
                  await _setDataUser(currentUser);
                  await Navigator.push(context,
                      CupertinoPageRoute(builder: (context) => Home()));
                }
              },
            ),
            SizedBox(width: 20),
            InkWell(
              child: Material(
                child: SvgPicture.asset(
                  'asset/img/social-icon/twitter.svg',
                  semanticsLabel: 'Acme Logo',
                  height: 35,
                  width: 35,
                ),
              ),
              onTap: () async {
                final FirebaseUser currentUser = await handleTwitterLogin();
                print(currentUser);
                if (currentUser != null) {
                  await _setDataUser(currentUser);
                  await Navigator.push(context,
                      CupertinoPageRoute(builder: (context) => Home()));
                }
              },
            ),
            SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  Widget signupButtonWidget() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text("You do not have an account?"),
          InkWell(
            onTap: () {
              Navigator.push(
                  context, CupertinoPageRoute(builder: (context) => Signup()));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Text(
                " Register Now!",
                style: TextStyle(color: Color(0xFFB74951)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<FirebaseUser> _handleGoogleSignIn() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final FirebaseUser user =
        (await _auth.signInWithCredential(credential)).user;
    return user;
  }

  Future<FirebaseUser> handleTwitterLogin() async {
    FirebaseUser user;
    AuthCredential result = await Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => TwitterLoginScreen(
                  consumerKey:
                      GlobalConfiguration().getString("twitterConsumerKey"),
                  consumerSecret:
                      GlobalConfiguration().getString("twitterConsumerSecret"),
                  oauthCallbackHandler:
                      GlobalConfiguration().getString("twitterCallbackHandler"),
                )));
    if (result != null) {
      try {
        user = (await FirebaseAuth.instance.signInWithCredential(result)).user;
        print('user $user');
      } catch (e) {
        print('Error $e');
      }
    }
    return user;
  }

  Future<FirebaseUser> handleFacebookLogin() async {
    FirebaseUser user;
    String result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CustomWebView(
                selectedUrl:
                    'https://www.facebook.com/dialog/oauth?client_id=${GlobalConfiguration().getString("FbAppid")}&redirect_uri=${GlobalConfiguration().getString("FBAuthHandler_redirect_url")}&response_type=token&scope=email,public_profile,',
              ),
          maintainState: true),
    );
    if (result != null) {
      try {
        final facebookAuthCred =
            FacebookAuthProvider.credential(result);
        user =
            (await FirebaseAuth.instance.signInWithCredential(facebookAuthCred))
                .user;

        print('user $user');
      } catch (e) {
        print('Error $e');
      }
    }
    return user;
  }

  Future<UserCredential> _handleSignIn(_data) async {
    UserCredential firebaseAuth;
    try {
      firebaseAuth = await _auth.signInWithEmailAndPassword(
          email: _data.email, password: _data.password);

      print(firebaseAuth.user.uid);
    } catch (err) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text(err.message),
        duration: Duration(seconds: 5),
      ));
      throw (err);
    }
    _setDataUser(firebaseAuth.user.uid);
    return firebaseAuth;
  }
}

Future _setDataUser(currentUser) async {
  Map metaData = {
    "createdBy": "0L1uQlYHdrdrG0D5CroAeybZsL33",
    "createdDate": DateTime.now(),
    "docId": currentUser.uid,
    "env": "production",
    "fl_id": currentUser.uid,
    "locale": "en-US",
    "schema": "users",
    "schemaRef": "fl_schemas/RIGJC2G8tsCBml0270IN",
    "schemaType": "collection",
  };
  try {
    if (currentUser.uid != null) {
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      Firestore.instance
          .collection('fl_content')
          .where('_fl_meta_.fl_id', isEqualTo: currentUser.uid)
          .getDocuments()
          .then((QuerySnapshot snapshot) async {
        // check if user exists.
        if (snapshot.documents.length <= 0) {
          Firestore.instance
              .collection("fl_content")
              .document(currentUser.uid)
              .setData({
            "_fl_meta_": metaData,
            "email": currentUser.email,
            "name": currentUser.displayName,
            "photoUrl": currentUser.photoUrl,
            "joiningDate": DateTime.now().toString()
          },);
        }
      });
    }
  } catch (err) {
    print("Error: $err");
  }
}
