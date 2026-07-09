// ─────────────────────────────────────────────────────────────────────────────
// screens/user/login_screen.dart  (new file — separate from admin login)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../theme/user_theme.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'register_screen.dart';
import 'auctions_screen.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _authService = AuthService();
  final _notifService = NotificationService();

  bool _obscure  = true;
  bool _loading  = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    _notifService.requestPermission();

    setState(() { _loading = true; _error = null; });

    final result = await _authService.login(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      // Save FCM token
      final token = await _notifService.getToken();
      if (token != null) {
        await _authService.updateFcmToken(result.user!.uid, token);
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuctionsScreen()),
      );
    } else {
      setState(() {
        _loading = false;
        _error = result.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UserTheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: Responsive.maxFormWidth(context)),
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: UserTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.gavel_rounded,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(height: 16),
                          Text('Welcome Back to BidForge',
                              style: UserTextStyles.h2.copyWith(
                                  fontSize:
                                      Responsive.fs(context, 22))),
                          const SizedBox(height: 4),
                          const Text('Sign in to start bidding',
                              style: UserTextStyles.label),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Error
                    if (_error != null) ...[
                      _ErrorBanner(_error!),
                      const SizedBox(height: 14),
                    ],

                    // Fields card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: UserTheme.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Credentials',
                              style: UserTextStyles.label),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'name@example.com',
                            ),
                            validator: (v) =>
                                (v == null || !v.contains('@'))
                                    ? 'Enter a valid email'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                    () => _obscure = !_obscure),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(right: 12),
                                  child: Text(
                                    _obscure ? 'SHOW' : 'HIDE',
                                    style: const TextStyle(
                                      color: UserTheme.primaryBlue,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              suffixIconConstraints:
                                  const BoxConstraints(minWidth: 60),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty)
                                    ? 'Password required'
                                    : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white))
                            : const Text('Sign In to BidForge'),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Register link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const UserRegisterScreen()),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: UserTextStyles.body.copyWith(
                                color: UserTheme.textSecondary),
                            children: const [
                              TextSpan(
                                  text: "Don't have an account? "),
                              TextSpan(
                                text: 'Create Account',
                                style: TextStyle(
                                  color: UserTheme.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: UserTheme.errorRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UserTheme.errorRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: UserTheme.errorRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: UserTheme.errorRed, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
