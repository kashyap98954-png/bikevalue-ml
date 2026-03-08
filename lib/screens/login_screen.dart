// lib/screens/login_screen.dart
// Login, Signup, Admin Login — tabbed design

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_theme.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../models/app_models.dart';
import 'home_screen.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = false;

  // Login
  final _loginEmailCtrl    = TextEditingController();
  final _loginPassCtrl     = TextEditingController();
  // Signup
  final _signupIdCtrl      = TextEditingController();
  final _signupEmailCtrl   = TextEditingController();
  final _signupPassCtrl    = TextEditingController();
  // Admin
  final _adminEmailCtrl    = TextEditingController();
  final _adminPassCtrl     = TextEditingController();

  bool _loginObscure  = true;
  bool _signupObscure = true;
  bool _adminObscure  = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: AppTheme.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _doLogin() async {
    if (_loginEmailCtrl.text.isEmpty || _loginPassCtrl.text.isEmpty) {
      _showError('Please fill in all fields.'); return;
    }
    setState(() => _loading = true);
    final res = await ApiService.login(
      email: _loginEmailCtrl.text.trim(),
      password: _loginPassCtrl.text,
    );
    setState(() => _loading = false);
    if (res['success'] == true) {
      final user = UserModel.fromJson(res);
      await SessionService.saveUser(user);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(user: user)));
    } else {
      _showError(res['message'] ?? 'Login failed');
    }
  }

  Future<void> _doSignup() async {
    if (_signupIdCtrl.text.isEmpty || _signupEmailCtrl.text.isEmpty || _signupPassCtrl.text.isEmpty) {
      _showError('Please fill in all fields.'); return;
    }
    setState(() => _loading = true);
    final res = await ApiService.signup(
      userId: _signupIdCtrl.text.trim(),
      email: _signupEmailCtrl.text.trim(),
      password: _signupPassCtrl.text,
    );
    setState(() => _loading = false);
    if (res['success'] == true) {
      final user = UserModel.fromJson(res);
      await SessionService.saveUser(user);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(user: user)));
    } else {
      _showError(res['message'] ?? 'Signup failed');
    }
  }

  Future<void> _doAdminLogin() async {
    if (_adminEmailCtrl.text.isEmpty || _adminPassCtrl.text.isEmpty) {
      _showError('Please fill in all fields.'); return;
    }
    setState(() => _loading = true);
    final res = await ApiService.adminLogin(
      email: _adminEmailCtrl.text.trim(),
      password: _adminPassCtrl.text,
    );
    setState(() => _loading = false);
    if (res['success'] == true) {
      final user = UserModel.fromJson(res);
      await SessionService.saveUser(user);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminScreen(user: user)));
    } else {
      _showError(res['message'] ?? 'Admin login failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.2,
            colors: [Color(0x207C5CFC), AppTheme.bg],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                // Logo
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [AppTheme.violet1, AppTheme.blue1],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    boxShadow: [BoxShadow(color: AppTheme.violet1.withOpacity(0.35), blurRadius: 24, spreadRadius: 2)],
                  ),
                  child: const Center(child: Text('⚡', style: TextStyle(fontSize: 32))),
                ),
                const SizedBox(height: 20),
                Text('BIKEVALUE',
                  style: GoogleFonts.playfairDisplay(
                    color: AppTheme.textPrimary, fontSize: 26,
                    fontWeight: FontWeight.w900, letterSpacing: 5,
                  )),
                const SizedBox(height: 6),
                Text('Precision Bike Valuation',
                  style: GoogleFonts.outfit(color: AppTheme.muted, fontSize: 12, letterSpacing: 2)),
                const SizedBox(height: 36),

                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: TabBar(
                    controller: _tabCtrl,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: AppTheme.violet1.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: AppTheme.violet2,
                    unselectedLabelColor: AppTheme.muted,
                    labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12),
                    tabs: const [
                      Tab(text: 'LOGIN'),
                      Tab(text: 'SIGNUP'),
                      Tab(text: 'ADMIN'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 380,
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildLoginForm(),
                      _buildSignupForm(),
                      _buildAdminForm(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() => Column(
    children: [
      _field(_loginEmailCtrl, 'Email Address', Icons.email_outlined, false),
      const SizedBox(height: 14),
      _field(_loginPassCtrl, 'Password', Icons.lock_outline, _loginObscure,
        suffix: IconButton(
          icon: Icon(_loginObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.muted, size: 18),
          onPressed: () => setState(() => _loginObscure = !_loginObscure),
        )),
      const SizedBox(height: 24),
      _submitBtn('Log In', _doLogin),
    ],
  );

  Widget _buildSignupForm() => Column(
    children: [
      _field(_signupIdCtrl, 'Username', Icons.person_outline, false),
      const SizedBox(height: 14),
      _field(_signupEmailCtrl, 'Email Address', Icons.email_outlined, false),
      const SizedBox(height: 14),
      _field(_signupPassCtrl, 'Password (min 6 chars)', Icons.lock_outline, _signupObscure,
        suffix: IconButton(
          icon: Icon(_signupObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.muted, size: 18),
          onPressed: () => setState(() => _signupObscure = !_signupObscure),
        )),
      const SizedBox(height: 24),
      _submitBtn('Create Account', _doSignup),
    ],
  );

  Widget _buildAdminForm() => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.violet1.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.violet1.withOpacity(0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.shield_outlined, color: AppTheme.violet2, size: 16),
          const SizedBox(width: 8),
          Text('Admin access only', style: GoogleFonts.outfit(color: AppTheme.violet2, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 16),
      _field(_adminEmailCtrl, 'Admin Email', Icons.admin_panel_settings_outlined, false),
      const SizedBox(height: 14),
      _field(_adminPassCtrl, 'Admin Password', Icons.lock_outline, _adminObscure,
        suffix: IconButton(
          icon: Icon(_adminObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.muted, size: 18),
          onPressed: () => setState(() => _adminObscure = !_adminObscure),
        )),
      const SizedBox(height: 24),
      _submitBtn('Admin Login', _doAdminLogin),
    ],
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon, bool obscure, {Widget? suffix}) =>
    TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: label.contains('Email') ? TextInputType.emailAddress : TextInputType.text,
      style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.muted, size: 18),
        suffixIcon: suffix,
      ),
    );

  Widget _submitBtn(String label, VoidCallback onTap) =>
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        child: _loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label),
      ),
    );
}
