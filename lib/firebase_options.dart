// ======================================================================
// ARQUIVO: lib/firebase_options.dart
// ======================================================================
// Este arquivo define as configurações manuais do Firebase para o app.
// Normalmente ele é gerado automaticamente pelo comando:
//
//     flutterfire configure
//
// Mas aqui foi feito manualmente com base nos dados do arquivo
// "google-services.json" do projeto Firebase.
// ======================================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

// ----------------------------------------------------------------------
// CLASSE PRINCIPAL DE CONFIGURAÇÃO DO FIREBASE
// ----------------------------------------------------------------------
// Essa classe fornece as opções corretas (FirebaseOptions)
// dependendo da plataforma (Android, iOS, Web, etc).
// No caso deste app, foi configurado apenas para Android.
class DefaultFirebaseOptions {
  // --------------------------------------------------------------------
  // Getter estático que retorna as opções da plataforma atual
  // --------------------------------------------------------------------
  static FirebaseOptions get currentPlatform {
    // 🚨 Neste caso, o app foi configurado apenas para Android.
    // Se for executado em outra plataforma (ex: web, iOS, desktop),
    // será lançada uma exceção.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'A configuração da plataforma $defaultTargetPlatform ainda não foi adicionada manualmente.',
        );
    }
  }

  // --------------------------------------------------------------------
  // CONFIGURAÇÕES DO FIREBASE PARA ANDROID
  // --------------------------------------------------------------------
  // Esses dados foram copiados diretamente do arquivo google-services.json
  // gerado pelo Firebase Console.
  //
  // 🔑 apiKey             → chave de autenticação do Firebase
  // 🆔 appId              → identificador único do app
  // 📩 messagingSenderId → ID para o Firebase Cloud Messaging (notificações push)
  // 🏗️ projectId          → ID do projeto Firebase
  // ☁️ storageBucket      → caminho do armazenamento (para arquivos/imagens)
  // 🔗 databaseURL        → (opcional) caso use Realtime Database
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAfoL7uRFo8nBCKe_WpIYsDqppaoLn0I3g',
    appId: '1:612229416801:android:501f1d7ad2554d71aae720',
    messagingSenderId: '612229416801',
    projectId: 'criptonexus-e1274',
    storageBucket: 'criptonexus-e1274.appspot.com',
    databaseURL: null, // não está sendo usado neste projeto
  );
}
