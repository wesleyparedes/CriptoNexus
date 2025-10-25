import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    const appBackgroundColor = Color(0xFF07070C);
    const fieldColor = Color(0xFF1A1A1A);
    const buttonBlue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          width: double.infinity,
          color: appBackgroundColor,
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Criar Conta',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Comece sua jornada no CriptoNexus',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 28),
                  _inputField(controller: _nameCtrl, hint: 'Nome Completo', icon: Icons.badge, fieldColor: fieldColor),
                  const SizedBox(height: 12),
                  _inputField(controller: _userCtrl, hint: 'E-mail', icon: Icons.person, fieldColor: fieldColor),
                  const SizedBox(height: 12),
                  _inputField(controller: _passCtrl, hint: 'Senha', icon: Icons.lock, obscure: true, fieldColor: fieldColor),
                  const SizedBox(height: 12),
                  _inputField(controller: _confirmPassCtrl, hint: 'Confirmar Senha', icon: Icons.lock_outline, obscure: true, fieldColor: fieldColor),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: _loading ? null : _signUp,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: buttonBlue,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: buttonBlue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Cadastrar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                    child: const Text(
                      "Já tem uma conta? Entre!",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    if (_passCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_nameCtrl.text.trim().isEmpty || _userCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _userCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'fullName': _nameCtrl.text.trim(),
        'email': _userCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fullName', _nameCtrl.text.trim());
      await prefs.setString('username', _userCtrl.text.trim());
      await prefs.setString('uid', cred.user!.uid);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado com sucesso!')),
      );

      Navigator.pushReplacementNamed(context, '/dashboard');
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'E-mail já está cadastrado.';
          break;
        case 'invalid-email':
          msg = 'E-mail inválido.';
          break;
        case 'weak-password':
          msg = 'A senha é muito fraca.';
          break;
        default:
          msg = 'Erro inesperado: ${e.message ?? e.code}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _inputField({
    TextEditingController? controller,
    String? hint,
    IconData? icon,
    bool obscure = false,
    required Color fieldColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white70),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}
