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

  /// Verifica se há uma nova versão disponível no GitHub
  static Future<void> checkForUpdate(BuildContext context,
      {bool showManualCheck = false}) async {
    const dark = Color(0xFF07070C);
    const blue = Color(0xFF2563EB);

    try {
      final info = await PackageInfo.fromPlatform();

      // ✅ Garante que a versão sempre tenha formato 1.0.0
      final currentVersion = _normalizeVersion(
        info.version.contains('.') ? info.version : "${info.version}.0.0",
      );
      debugPrint("📦 Versão atual normalizada: $currentVersion");

      String latestVersion = fallbackVersion;
      String apkUrl = fallbackApkUrl;

      final response = await http.get(Uri.parse(repoApiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        latestVersion = _normalizeVersion(data['tag_name']?.toString());
        final assets = data['assets'] as List?;
        if (assets != null && assets.isNotEmpty) {
          apkUrl = assets[0]['browser_download_url'];
        }
      }

      debugPrint("🧩 Comparando versões → Atual: $currentVersion | Última: $latestVersion");
      debugPrint("📥 Link APK: $apkUrl");

      if (_isNewer(latestVersion, currentVersion)) {
        if (context.mounted) {
          _showUpdateDialog(context, latestVersion, apkUrl);
        }
      } else if (showManualCheck && context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: dark,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Tudo atualizado 🎉',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Você já está usando a versão mais recente do CriptoNexus.\n\n'
              'Nada a fazer por enquanto 🚀',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Ok',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao verificar atualização: $e');
      if (showManualCheck && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Falha ao verificar atualização."),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 🔧 Normaliza versões para formato consistente x.y.z e remove zeros extras
  static String _normalizeVersion(String? version) {
    if (version == null || version.trim().isEmpty) return "0.0.0";

    version = version.trim().toLowerCase();
    version = version.replaceAll(RegExp(r'[^0-9.]'), '');

    final parts = version.split('.').where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty) return "0.0.0";

    while (parts.length < 3) parts.add('0');
    if (parts.length > 3) parts.removeRange(3, parts.length);

    while (parts.length > 1 && parts.last == '0') {
      parts.removeLast();
    }

    return parts.join('.');
  }

  /// 🧩 Compara versões normalizadas (sem risco de erro)
  static bool _isNewer(String latest, String current) {
    latest = _normalizeVersion(latest);
    current = _normalizeVersion(current);

    List<int> l = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> c = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    while (l.length < 3) l.add(0);
    while (c.length < 3) c.add(0);

    for (int i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

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
          'Nova versão disponível 🚀',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Uma nova versão do CriptoNexus está disponível!\n\n'
          'Deseja baixar e instalar agora?',
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Mais tarde',
              style: TextStyle(color: Colors.white70),
            ),
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
            child: const Text(
              'Baixar e instalar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _downloadAndInstall(
      BuildContext context, String apkUrl) async {
    const dark = Color(0xFF07070C);
    const blue = Color(0xFF2563EB);

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/cripto_nexus_update.apk';
      final dio = Dio();
      double progress = 0;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: dark,
            title: const Text(
              'Baixando atualização...',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  color: blue,
                ),
                const SizedBox(height: 16),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white70),
                ),
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
      if (context.mounted) Navigator.pop(context);
      debugPrint('❌ Erro ao baixar atualização: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erro ao baixar atualização."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
