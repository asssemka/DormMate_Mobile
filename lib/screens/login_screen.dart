import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginCtr = TextEditingController();
  final _passCtr = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkLoggedIn();
  }

  Future<void> _checkLoggedIn() async {
    final token = await AuthService.getAccessToken();
    if (token == null || token.isEmpty) return;

    var role = await AuthService.getUserType();
    role ??= await AuthService.fetchAndSaveUserType();

    if (!mounted) return;
    _goByRole(role);
  }

  Future<void> _handleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final id = _loginCtr.text.trim();
    final pw = _passCtr.text.trim();

    if (id.isEmpty || pw.isEmpty) {
      setState(() {
        _error = 'Введите идентификатор и пароль';
        _loading = false;
      });
      return;
    }

    final ok = await AuthService.login(id, pw);
    if (!mounted) return;

    if (ok) {
      var role = await AuthService.getUserType();
      role ??= await AuthService.fetchAndSaveUserType();
      _goByRole(role);
    } else {
      setState(() {
        _error = 'Неверные данные для входа';
        _loading = false;
      });
    }
  }

  void _goByRole(String? role) {
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/adminMain');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Widget _logo() => Padding(
        padding: EdgeInsets.only(top: 60.h, bottom: 40.h),
        child: Text(
          'DORM MATE',
          style: GoogleFonts.montserrat(
            fontSize: 42.sp,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFD50032),
          ),
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black87),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/dorm_background.png', // картинка как на макете
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.white.withOpacity(0.5),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _logo(),
                  _textField(
                    controller: _loginCtr,
                    hint: 'Login',
                    icon: Icons.person,
                  ),
                  _textField(
                    controller: _passCtr,
                    hint: 'Password',
                    icon: Icons.lock,
                    obscure: true,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD50032),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Sign In', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 40),
                  Image.asset('assets/logo.png', height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
