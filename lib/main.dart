import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/perfil_screen.dart';
import 'services/app_update_checker.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Mensagem recebida em segundo plano: ${message.messageId}");
}

void obterTokenFCM() async {
  final messaging = FirebaseMessaging.instance;
  final token = await messaging.getToken();
  print(token);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    obterTokenFCM();
    print("Firebase inicializado com sucesso!");
  } catch (e) {
    print("Erro ao inicializar Firebase: $e");
  }

  runApp(const CriptoNexusApp());
}

class CriptoNexusApp extends StatelessWidget {
  const CriptoNexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryDark = Color(0xFF0B0736);
    const purple = Color(0xFF7C4DFF);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CriptoNexus',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: primaryDark,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme.apply(bodyColor: Colors.white),
        ),
        colorScheme: const ColorScheme.dark(
          primary: purple,
          secondary: purple,
          surface: primaryDark,
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/perfil': (context) => const PerfilScreen(),
      },
    );
  }
}
