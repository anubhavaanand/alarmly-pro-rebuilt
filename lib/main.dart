import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

import 'models/alarm.dart';
import 'services/alarm_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/alarm_ring_screen.dart';

/// MethodChannel for receiving intents from native side
const MethodChannel _intentChannel = MethodChannel('com.wakemeup.intent');

/// Global navigator key for routing from outside widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data
  tz.initializeTimeZones();
  
  // Initialize Isar database
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [AlarmSchema],
    directory: dir.path,
  );
  
  // Initialize notification service
  await NotificationService.initialize();
  
  // Initialize alarm service
  await AlarmService.initialize(isar);
  
  // Request critical permissions
  await _requestPermissions();
  
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  runApp(WakeMeUpProApp(isar: isar));
}

Future<void> _requestPermissions() async {
  // Request notification permissions
  await Permission.notification.request();
  
  // Android-specific permissions
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }
  
  // Camera permission (for missions)
  await Permission.camera.request();
}

class WakeMeUpProApp extends StatefulWidget {
  final Isar isar;
  
  const WakeMeUpProApp({Key? key, required this.isar}) : super(key: key);

  @override
  State<WakeMeUpProApp> createState() => _WakeMeUpProAppState();
}

class _WakeMeUpProAppState extends State<WakeMeUpProApp> with WidgetsBindingObserver {
  Map<String, dynamic>? _pendingAlarmData;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupIntentChannel();
    _checkInitialIntent();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  /// Set up handler for incoming intents from native
  void _setupIntentChannel() {
    _intentChannel.setMethodCallHandler((call) async {
      if (call.method == 'launchAlarm') {
        final alarmData = Map<String, dynamic>.from(call.arguments);
        _navigateToAlarmRing(alarmData);
      }
    });
  }
  
  /// Check if app was launched with alarm intent
  Future<void> _checkInitialIntent() async {
    try {
      final result = await _intentChannel.invokeMethod('getInitialIntent');
      if (result != null) {
        _pendingAlarmData = Map<String, dynamic>.from(result);
      }
    } catch (e) {
      // Channel not set up yet on native side, ignore
      print('No initial intent available: $e');
    }
  }
  
  /// Navigate to alarm ring screen with parameters
  void _navigateToAlarmRing(Map<String, dynamic> alarmData) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamed(
        '/alarm-ring',
        arguments: alarmData,
      );
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingAlarmData != null) {
      _navigateToAlarmRing(_pendingAlarmData!);
      _pendingAlarmData = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wake Me Up Pro',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00F5FF), // Cyan
          secondary: const Color(0xFFFF00FF), // Magenta
          surface: const Color(0xFF1A1A2E),
          background: const Color(0xFF0F0F1E),
          error: const Color(0xFFFF3366),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        cardTheme: CardTheme(
          color: const Color(0xFF1A1A2E),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        // Add smooth page transitions
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Check for pending alarm data on initial route
        if (settings.name == '/' && _pendingAlarmData != null) {
          final alarmData = _pendingAlarmData;
          _pendingAlarmData = null;
          return MaterialPageRoute(
            settings: const RouteSettings(name: '/alarm-ring'),
            builder: (context) => AlarmRingScreen(initialData: alarmData),
          );
        }
        
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => HomeScreen(isar: widget.isar),
            );
          case '/alarm-ring':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => AlarmRingScreen(initialData: args),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => HomeScreen(isar: widget.isar),
            );
        }
      },
    );
  }
}
