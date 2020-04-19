import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:instagram_v2/models/user_data.dart';
import 'package:instagram_v2/screens/camera_screen.dart';
import 'package:instagram_v2/screens/gallery_screen.dart';
import 'package:instagram_v2/screens/social_screen.dart';
import 'package:instagram_v2/services/database_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  PageController _pageController;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  _setUpFCM() {
    _firebaseMessaging.requestNotificationPermissions();
    _firebaseMessaging.configure(
      onLaunch: (message) async {
        print('onLauch ${message.toString()}');
        return;
      },
      onMessage: (message) async{
        print('onMessage ${message.toString()}');
        showNotification(message);
        return;
      },
      onResume: (message) async{
        print('onResume ${message.toString()}');
        return;
      },

    );

    _firebaseMessaging.getToken().then((token) async {
      print(token);
      FirebaseUser user = await FirebaseAuth.instance.currentUser();
      DatabaseService.updateToken(user.uid, token);
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _setUpFCM();
    configLocalNotification();
  }

  Future<void> showNotification(message) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      'com.example.photogram',
      'Photogram',
      'channel for photogram',
      playSound: true,
      //enableVibration: true,
      importance: Importance.Max,
      priority: Priority.High,
        ticker: 'ticker'
    );
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics =
    new NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, message['notification']['title'].toString(), message['notification']['body'].toString(), platformChannelSpecifics,
        );
  }

  void configLocalNotification() {
    var initializationSettingsAndroid = new AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = Provider.of<UserData>(context).currentUserId;
    final themeStyle = Provider.of<UserData>(context);
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: <Widget>[
          SocialScreen(
            currentUserId: currentUserId,
          ),
          GalleyScreen(),
          CameraScreen()
        ],
        onPageChanged: (int index) {
          setState(() {
            _currentTab = index;
          });
        },
      ),
      bottomNavigationBar: CupertinoTabBar(
        backgroundColor: themeStyle.primaryBackgroundColor,
        currentIndex: _currentTab,
        onTap: (int index) {
          setState(() {
            _currentTab = index;
          });
          _pageController.animateToPage(
            index,
            duration: Duration(milliseconds: 200),
            curve: Curves.easeIn,
          );
        },
        activeColor: Colors.black,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              size: 32.0,
              color:
                  _currentTab == 0 ? Colors.blue : themeStyle.primaryIconColor,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.photo_library,
              size: 32.0,
              color:
                  _currentTab == 1 ? Colors.blue : themeStyle.primaryIconColor,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.camera,
              size: 32.0,
              color:
                  _currentTab == 2 ? Colors.blue : themeStyle.primaryIconColor,
            ),
          ),
        ],
      ),
    );
  }
}
