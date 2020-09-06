import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/create_account.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/pages/timeline.dart';
import 'package:fluttershare/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn googlesignin = GoogleSignIn();

final StorageReference storageRef = FirebaseStorage.instance.ref();

final userref = Firestore.instance.collection('users');
final postsRef = Firestore.instance.collection('posts');
final commentsRef=Firestore.instance.collection('comments');
final activityFeedRef=Firestore.instance.collection('feed');
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final timelineRef = Firestore.instance.collection('timeline');

final DateTime timestamp = DateTime.now();
User currentuser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  int pageIndex = 0;

  PageController pageController;
  @override
  void initState() {
    super.initState();
    pageController = PageController();
    googlesignin.onCurrentUserChanged.listen((account) {
      handelsignin(account);
    }, onError: (err) {
      print('eroor $err');
    });
    // Reauthenticate user when app is opened
    googlesignin.signInSilently(suppressErrors: false).then((account) {
      handelsignin(account);
    }).catchError((err) {
      print('Error signing in: $err');
    });
  }

  handelsignin(GoogleSignInAccount account)async {
    if (account != null) {
     await createuserinstore();
      print('yesss $account');

      setState(() {
        isAuth = true;
      });
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  createuserinstore() async {
    final GoogleSignInAccount user = googlesignin.currentUser;

    DocumentSnapshot doc = await userref.document(user.id).get();

    if (!doc.exists) {
      // 2) if the user doesn't exist, then we want to take them to the create account page
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));
      userref.document(user.id).setData({
        "id": user.id,
        "username": username,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        "timestamp": timestamp
      });
      // make new user their own follower (to include their own posts in their timeline)
      await followersRef
          .document(user.id)
          .collection('userFollowers')
          .document(user.id)
          .setData({});
      //update doc to current user document
      doc = await userref.document(user.id).get();
    }
    currentuser = User.fromDocument(doc);
    print(currentuser);
    print(currentuser.username);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  login() {
    googlesignin.signIn();
  }

  logout() {
    googlesignin.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(pageIndex,
        duration: Duration(milliseconds: 300), curve: Curves.bounceInOut);
  }

  Scaffold buildauthscreen() {
    return Scaffold(
      body: PageView(
        children: <Widget>[
          Timeline(currentuser:currentuser),
          ActivityFeed(),
          Upload(currentUser: currentuser),
          Search(),
          Profile(profileId:currentuser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
      //  physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
          currentIndex: pageIndex,
          onTap: onTap,
          activeColor: Theme.of(context).primaryColor,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.whatshot),
              title: Text('timeline',style: TextStyle(
                color:Theme.of(context).primaryColor ,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),),

            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_active),
              title: Text('Activity',style: TextStyle(
                color:Theme.of(context).primaryColor ,
                fontWeight: FontWeight.bold,

                fontSize: 10,
              ),),

            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.photo_camera,
                size: 35.0,
              ),
              title: Text('post',style: TextStyle(
                color:Theme.of(context).primaryColor ,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),),

            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              title: Text('search',style: TextStyle(
                color:Theme.of(context).primaryColor ,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),),

            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              title: Text('account',style: TextStyle(
                color:Theme.of(context).primaryColor ,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),),

            ),
          ]),
    );
    // return RaisedButton(
    //   child: Text('Logout'),
    //   onPressed: logout,
    // );
  }

  Scaffold buildscreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).primaryColorLight,
              Theme.of(context).accentColor,
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'KUET-Album',
              style: TextStyle(
                fontFamily: "Signatra",
                fontSize: 60.0,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260.0,
                height: 60.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/google_signin_button.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildauthscreen() : buildscreen();
  }
}
