import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:universus/Community/Community_Widget.dart';
import 'package:universus/Community/Post_Widget.dart';
import 'package:universus/Community/Write_Widget.dart';
import 'package:universus/Search/SearchResult_Widget.dart';
import 'package:universus/Search/Search_Widget.dart';
import 'package:universus/auth/AdditionalInfo_Widget.dart';
import 'package:universus/chat/ChatListWidget.dart';
import 'package:universus/class/user/user.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universus/main/main_Model.dart';

// Widget Import
import 'package:universus/auth/Login_Widget.dart';
import 'package:universus/club/ClubMain_Widget.dart';
import 'package:universus/club/CreateClub_Widget.dart';
import 'package:universus/club/MyClub_Widget.dart';
import 'package:universus/club/UpdateClub_Widget.dart';
import 'package:universus/component/MainPage.dart';
import 'package:universus/auth/CreateAccount_Widget.dart';
import 'package:universus/auth/PasswordForget_Widget.dart';
import 'package:universus/main/main_Widget.dart';
import 'package:universus/member/profile_Widget.dart';
import 'package:universus/member/updateProfile_Widget.dart';
import 'package:universus/test/testscreen_Widget.dart';
import 'package:universus/auth/tmp/KakaoLogin.dart';
import 'package:universus/shared/placepicker.dart';
import 'package:universus/versus/versusCreate_Widget.dart';
import 'package:universus/versus/versusList_Widget.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 1번코드
  KakaoSdk.init(
      nativeAppKey: 'c42d4f7154f511f29ae715dc77565878',
      javaScriptAppKey: '240cc5ab531ff61f42c8e0a1723a4f96');
  await dotenv.load(fileName: ".env"); // 2번코드
  initializeDateFormatting().then((_) => runApp(MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.light);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<bool> _loginInfo;

  @override
  void initState() {
    super.initState();
    _loginInfo = checkLoginInfo();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: MyApp.themeNotifier,
        builder: (context, ThemeMode value, child) {
          return MaterialApp(
            darkTheme: ThemeData.dark(),
            theme: ThemeData.light(),
            themeMode: value,
            initialRoute: '/',
            routes: {
              '/': (context) => FutureBuilder(
                    future: _loginInfo,
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SplashScreen();
                      } else {
                        if (snapshot.data == true) {
                          return TestscreenWidget();
                        } else {
                          return LoginWidget();
                        }
                      }
                    },
                  ),
              '/main': (context) => TestscreenWidget(),
              '/login': (context) => LoginWidget(),
              '/register': (context) => CreateAccountWidget(),
              '/passwordforgot': (context) => PasswordForgetWidget(),
              '/testscreen': (context) => TestscreenWidget(),
              '/testplacepicker': (context) => new PlacePickerScreen(),
              '/createClub': (context) => CreateClubWidget(),
              '/club/update': (context) => UpdateClubWidget(
                  clubId: "9"), // 테스트용 나중에 clubId 파라미터도 같이 전달해야함
              '/profile': (context) => ProfileWidget(),
              '/chat/main.dart': (context) => ChatListScreen(chatItems: [
                    ChatItem(title: '채팅방 1', subtitle: '채팅방 1 설명'),
                    ChatItem(title: '채팅방 2', subtitle: '채팅방 2 설명'),
                    ChatItem(title: '채팅방 3', subtitle: '채팅방 3 설명'),
                  ]),
              '/main1': (context) => MainWidget(),
              '/versusList': (context) => VersusListWidget(),
              '/versusCreate': (context) => versusCreateWidget(),
              '/Search': (context) => SearchWidget(),
              '/SearchResult': (context) => SearchResultWidget(),
              '/Community': (context) => CommunityWidget(),
              '/Post': (context) => PostWidget(),
              '/Write': (context) => WriteWidget(),
              '/ClubMain': (context) => ClubMainWidget(),
              '/MyClub': (context) => MyClubWidget(),

            },
          );
        });
  }

  Future<bool> checkLoginInfo() async {
    // 유저 정보 확인 메서드
    await Future.delayed(Duration(seconds: 3)); // Show logo for 3 seconds
    UserData? user = await UserData.getUser();
    return user != null;
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _logoSize = 0.0;

  @override
  void initState() {
    super.initState();
    _animateLogo();
  }

  void _animateLogo() {
    Future.delayed(Duration(milliseconds: 50), () {
      setState(() {
        _logoSize = 250;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(
              duration: Duration(seconds: 2),
              curve: Curves.easeOutCubic,
              width: _logoSize,
              height: _logoSize,
              child: Image.asset('assets/images/logo.png'),
            ),
            SizedBox(height: 20),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(seconds: 2),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Text('대학교끼리 경쟁을 해보세요!',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
