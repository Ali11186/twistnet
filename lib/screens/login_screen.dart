import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {
        _isValid = _phoneController.text.length >= 10;
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.sendOtp(_phoneController.text);

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const OtpScreen(),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'حدث خطأ'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              
              // Logo
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wifi_tethering,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              Text(
                'تسجيل الدخول',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 10),
              
              Text(
                'أدخل رقم الهاتف لإرسال رمز التحقق',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Phone Input
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  hintText: '01xxxxxxxxx',
                  prefixIcon: const Icon(Icons.phone),
                  suffixIcon: _isValid
                      ? const Icon(Icons.check_circle, color: AppTheme.successColor)
                      : null,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Send Button
              ElevatedButton(
                onPressed: auth.isLoading || !_isValid ? null : _sendOtp,
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('إرسال رمز التحقق'),
              ),
              
              const SizedBox(height: 20),
              
              // Saved Sessions
              if (auth.sessions.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  'الأرقام المحفوظة',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...auth.sessions.map((session) {
                  final phone = session['phone'] ?? '';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.successColor,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        phone,
                        style: GoogleFonts.cairo(),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final success = await auth.loginWithSavedSession(session);
                        if (!success && mounted) {
                          // Session expired, go to OTP
                          auth.sendOtp(phone);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OtpScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
