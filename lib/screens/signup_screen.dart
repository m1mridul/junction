import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final ScrollController _scrollController = ScrollController();
  bool _wasKeyboardOpen = false;

  // প্রতিটি ফিল্ডের জন্য আলাদা FocusNode
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('পাসওয়ার্ড নিশ্চিতকরণের সাথে মিলছে না!')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    _resetScroll();

    setState(() => _isLoading = true);
    try {
      final res = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'full_name': _nameController.text.trim()},
      );

      if (res.user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('অ্যাকাউন্ট সফলভাবে তৈরি হয়েছে! লগইন করুন।')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'নিবন্ধন ব্যর্থ হয়েছে।';
        final errorStr = e.toString();

        if (errorStr.contains('SocketException') ||
            errorStr.contains('Failed host lookup') ||
            errorStr.contains('No address associated with hostname')) {
          errorMessage =
              'ইন্টারনেট সংযোগ নেই। অনুগ্রহ করে ইন্টারনেট চালু করে আবার চেষ্টা করুন।';
        } else if (errorStr.contains('User already registered')) {
          errorMessage = 'এই ইমেইল দিয়ে ইতিমধ্যে অ্যাকাউন্ট আছে।';
        } else if (errorStr.contains('Password should be')) {
          errorMessage = 'পাসওয়ার্ড খুব দুর্বল।';
        } else {
          errorMessage = 'নিবন্ধন ব্যর্থ: $e';
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
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                    SizedBox(height: size.height * 0.04),

                    // লোগো
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 130,
                        width: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => const Icon(
                          Icons.balance,
                          size: 100,
                          color: Color(0xFFE5B25D),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

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

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_emailFocus);
                      },
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'আপনার সম্পূর্ণ নাম লিখুন'
                          : null,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: _inputDecoration(
                        hintText: 'আপনার সম্পূর্ণ নাম লিখুন',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 12),

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
                    const SizedBox(height: 12),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context)
                            .requestFocus(_confirmPasswordFocus);
                      },
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
                    const SizedBox(height: 12),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocus,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signUp(),
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'পাসওয়ার্ড নিশ্চিত করুন'
                          : null,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: _inputDecoration(
                        hintText: 'পাসওয়ার্ড নিশ্চিত করুন',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Gold Button
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
                        onPressed: _isLoading ? null : _signUp,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Color(0xFF032836), strokeWidth: 2),
                              )
                            : const Text(
                                'অ্যাকাউন্ট নিবন্ধন',
                                style: TextStyle(
                                  color: Color(0xFF032836),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Navigation back to Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('ইতিমধ্যে অ্যাকাউন্ট আছে?',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'লগইন করুন',
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
