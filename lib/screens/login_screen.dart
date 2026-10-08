import 'package:flutter/material.dart';
import 'package:junction/screens/main_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final ScrollController _scrollController = ScrollController();
  bool _wasKeyboardOpen = false;

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _supabase = Supabase.instance.client;

  void _resetScroll() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    _resetScroll();

    setState(() => _isLoading = true);
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (res.session != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        // ✅ এরর মেসেজ পরিষ্কার করা
        String errorMessage = 'লগইন ব্যর্থ হয়েছে।';
        final errorStr = e.toString();

        if (errorStr.contains('SocketException') ||
            errorStr.contains('Failed host lookup') ||
            errorStr.contains('No address associated with hostname')) {
          errorMessage =
              'ইন্টারনেট সংযোগ নেই। অনুগ্রহ করে ইন্টারনেট চালু করে আবার চেষ্টা করুন।';
        } else if (errorStr.contains('Invalid login credentials')) {
          errorMessage = 'ইমেইল বা পাসওয়ার্ড ভুল।';
        } else if (errorStr.contains('Email not confirmed')) {
          errorMessage = 'ইমেইল এখনো কনফার্ম করা হয়নি। ইমেইল চেক করুন।';
        } else if (errorStr.contains('network')) {
          errorMessage = 'নেটওয়ার্ক সমস্যা। আবার চেষ্টা করুন।';
        } else {
          errorMessage = 'লগইন ব্যর্থ: $e';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    // কীবোর্ড বন্ধ হলে স্ক্রল রিসেট
    if (_wasKeyboardOpen && !isKeyboardOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resetScroll();
      });
    }
    _wasKeyboardOpen = isKeyboardOpen;

    return Scaffold(
      backgroundColor: const Color(0xFF032836),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ১. নিচের দিকের গ্যাভেল ইমেজ
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.35,
            child: ClipRect(
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black],
                    stops: [0.0, 0.4],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/images/judge_gavel.png',
                  width: size.width,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (ctx, err, stack) => const SizedBox(),
                ),
              ),
            ),
          ),

          // ২. ইমেজের উপরে শেড
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.35,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF032836).withOpacity(0.0),
                    const Color(0xFF032836).withOpacity(0.2),
                    const Color(0xFF032836).withOpacity(0.6),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ৩. ফর্ম কন্টেন্ট লেয়ার
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              // ৪. কীবোর্ড বন্ধ থাকলে স্ক্রল হবে না, ওপেন থাকলে স্ক্রল হবে
              physics: isKeyboardOpen
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                bottom:
                    isKeyboardOpen ? keyboardHeight + 20 : size.height * 0.35,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: size.height * 0.06),

                    // লোগো
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 150,
                        width: 220,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => const Icon(
                          Icons.balance,
                          size: 120,
                          color: Color(0xFFE5B25D),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'স্বাগতম',
                      style: TextStyle(
                        color: Color(0xFFE5B25D),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),

                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Serif',
                        ),
                        children: [
                          TextSpan(
                            text: 'Law ',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: 'Junction',
                            style: TextStyle(color: Color(0xFFE5B25D)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'আপনার ব্যক্তিগত কেস ম্যানেজার',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 30),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocus);
                      },
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'আপনার ইমেইল লিখুন'
                          : null,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: _inputDecoration(
                        hintText: 'আপনার ইমেইল লিখুন',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'আপনার পাসওয়ার্ড লিখুন'
                          : null,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: _inputDecoration(
                        hintText: 'আপনার পাসওয়ার্ড লিখুন',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // পাসওয়ার্ড ভুলে গেছেন?
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'পাসওয়ার্ড ভুলে গেছেন?',
                          style:
                              TextStyle(color: Color(0xFFE5B25D), fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // গোল্ডেন লগইন বাটন
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF3D382), Color(0xFFD49E41)],
                        ),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Color(0xFF032836), strokeWidth: 2),
                              )
                            : const Text(
                                'লগইন',
                                style: TextStyle(
                                  color: Color(0xFF032836),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // সাইন আপ লিংক
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('অ্যাকাউন্ট নেই?',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignUpScreen()),
                            );
                          },
                          child: const Text(
                            'নতুন অ্যাকাউন্ট খুলুন',
                            style: TextStyle(
                              color: Color(0xFFE5B25D),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.white70, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF07384A).withValues(alpha: 0.4),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1B5368)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5B25D)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
