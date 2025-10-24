import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_update_checker.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String? _profileImagePath;
  bool _isEditing = false;

  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _fullNameCtrl.text = data['fullName'] ?? '';
        _usernameCtrl.text = data['email'] ?? '';
        _emailCtrl.text = data['email'] ?? '';
      } else {
        _fullNameCtrl.text = prefs.getString('fullName') ?? '';
        _usernameCtrl.text = prefs.getString('username') ?? '';
        _emailCtrl.text = prefs.getString('email') ?? '';
      }

      setState(() {
        _profileImagePath = prefs.getString('profileImage');
      });
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'fullName': _fullNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      });

      await prefs.setString('fullName', _fullNameCtrl.text.trim());
      await prefs.setString('email', _emailCtrl.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informações atualizadas com sucesso!')),
      );

      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    var cameraStatus = await Permission.camera.request();
    var photosStatus = await Permission.photos.request();

    if (cameraStatus.isDenied || photosStatus.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissão negada. Habilite acesso à câmera e galeria.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.white),
              title: const Text('Tirar foto', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final picked = await picker.pickImage(source: ImageSource.camera);
                if (picked != null) _saveProfileImage(picked);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Escolher da galeria', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final picked = await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) _saveProfileImage(picked);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfileImage(XFile pickedFile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImage', pickedFile.path);
    setState(() => _profileImagePath = pickedFile.path);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const appBackgroundColor = Color(0xFF07070C);
    const buttonColor = Color(0xFF7AF0FF);

    return Scaffold(
      backgroundColor: appBackgroundColor,
      extendBody: true,
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: BottomAppBar(
            color: const Color(0xFF07070C).withOpacity(0.9),
            height: 65 + MediaQuery.of(context).padding.bottom,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 80,
                  child: _navItem(
                    icon: Icons.home,
                    label: 'Início',
                    onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: _navItem(
                    icon: Icons.account_circle,
                    label: 'Perfil',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.black,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Seu Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit, color: Colors.white),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0x1FFFFFFF),
                      backgroundImage: _profileImagePath != null
                          ? FileImage(File(_profileImagePath!))
                          : null,
                      child: _profileImagePath == null
                          ? const Icon(Icons.person, size: 60, color: Colors.white38)
                          : null,
                    ),
                    if (_isEditing)
                      Container(
                        decoration: const BoxDecoration(
                          color: buttonColor,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _fullNameCtrl,
                readOnly: !_isEditing,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Nome Completo'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameCtrl,
                readOnly: true,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Usuário (E-mail)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailCtrl,
                readOnly: !_isEditing,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('E-mail'),
              ),

              const SizedBox(height: 30),

              GestureDetector(
  onTap: () => AppUpdateChecker.checkForUpdate(context, showManualCheck: true),
  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFF2563EB), // azul igual ao botão Calcular
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Center(
      child: Text(
        'Verificar atualização',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white, // texto branco pra contraste
        ),
      ),
    ),
  ),
),


              const SizedBox(height: 16),

              GestureDetector(
                onTap: _logout,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Sair da Conta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
