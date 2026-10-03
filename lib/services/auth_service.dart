import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Currently logged-in user getting
  User? get currentUser => _supabase.auth.currentUser;

  // Session state change listener stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // 1. Sign Up (Email & Password)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  // 2. Sign In / Login (Email & Password)
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // 3. Sign Out / Logout
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}