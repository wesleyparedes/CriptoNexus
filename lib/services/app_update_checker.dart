import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class AppUpdateChecker {
  static const String repoApiUrl =
      'https://api.github.com/repos/wesleyparedes/CriptoNexus/releases/latest';

  static const String fallbackVersion = "1.0.0";
  static const String fallbackApkUrl =
      "https://github.com/wesleyparedes/CriptoNexus/releases/download/v1.0.0/app-release.apk";

  /// 🔍 Verifica se há nova versão no GitHub (automática ou manual)
  static Future<void> checkForUpdate(BuildContext context,
      {bool showManualCheck = false}) async {
    const dark = Color(0xFF07070C);
    const blue = Color(0xFF2563EB);

    try {
      final info = await PackageInfo.fromPlatform();
      final prefs = await SharedPreferences.getInstance();

      // versão atual normalizada (ex: 1.0 → 1.0.0)
      final currentVersion = _normalizeVersion(info.version);
      debugPrint("📦 Versão atual: $currentVersion");

      // evita chamadas repetidas (verifica 1x por dia)
      final lastCheck = prefs.getInt('last_update_check') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (!showManualCheck && now - lastCheck < 86400000) return;
      prefs.setInt('last_update_check', now);

      // 🔎 busca a última versão do GitHub
      final response = await http.get(Uri.parse(repoApiUrl));
      if (response.statusCode != 200) throw Exception("Erro ${response.statusCode}");

      final data = jsonDecode(response.body);
      final latestVersion = _normalizeVersion(data['tag_name']);
      final apkUrl = (data['assets'] != null && data['assets'].isNotEmpty)
          ? data['assets'][0]['browser_download_url']
          : fallbackApkUrl;

      debugPrint("🧩 Última versão: $latestVersion");
      debugPrint("📥 APK: $apkUrl");

      if (_isNewer(latestVersion, currentVersion)) {
        if (context.mounted) _showUpdateDialog(context, latestVersion, apkUrl);
      } else if (showManualCheck && context.mounted) {
        _showInfoDialog(context, "Tudo atualizado 🎉",
            "Você já está usando a versão mais recente do CriptoNexus 🚀");
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao verificar atualização: $e');
      if (showManualCheck && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Falha ao verificar atualização."),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 🔧 Normaliza formato de versão → sempre x.y.z
  static String _normalizeVersion(String? version) {
    if (version == null || version.trim().isEmpty) return "0.0.0";
    version = version.trim().toLowerCase().replaceAll(RegExp(r'[^0-9.]'), '');
    final parts = version.split('.').where((e) => e.isNotEmpty).toList();
    while (parts.length < 3) parts.add('0');
    return parts.take(3).join('.');
  }

  /// 📊 Compara versões (ex: 1.0.9 < 1.1.0)
  static bool _isNewer(String latest, String current) {
    final l = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final c = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  /// 💬 Mostra alerta de nova atualização
  static void _showUpdateDialog(
      BuildContext context, String version, String apkUrl) {
    const dark = Color(0xFF07070C);
    const blue = Color(0xFF2563EB);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: dark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '🚀 Nova versão disponível',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Versão $version do CriptoNexus já está disponível!\n\nDeseja baixar agora?',
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mais tarde',
                style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstall(context, apkUrl);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: blue,
              minimumSize: const Size(140, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text('Baixar e instalar',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// 📥 Faz download + instala o APK
  static Future<void> _downloadAndInstall(
      BuildContext context, String apkUrl) async {
    const dark = Color(0xFF07070C);
    const blue = Color(0xFF2563EB);

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/criptonexus_update.apk';
      final dio = Dio();

      double progress = 0.0;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: dark,
            title: const Text('Baixando atualização...',
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  color: blue,
                  backgroundColor: Colors.white10,
                ),
                const SizedBox(height: 16),
                Text("${(progress * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      );

      await dio.download(
        apkUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            progress = received / total;
            (context as Element).markNeedsBuild();
          }
        },
      );

      if (context.mounted) Navigator.pop(context);
      await OpenFilex.open(filePath);
    } catch (e) {
      debugPrint('❌ Erro ao baixar atualização: $e');
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro ao baixar atualização."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// 🪄 Mostra alerta informativo (ex: app já atualizado)
  static void _showInfoDialog(
      BuildContext context, String title, String message) {
    const dark = Color(0xFF07070C);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: dark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(message,
            style: const TextStyle(color: Colors.white70, fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
