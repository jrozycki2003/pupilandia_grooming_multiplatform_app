/// \file login.dart
/// \brief Strona logowania użytkownika
/// 
/// Umożliwia zalogowanie się do aplikacji przy użyciu email i hasła.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kubaproject/pages/home.dart';
import 'package:kubaproject/services/shared_pref.dart';
import 'package:kubaproject/pages/signup.dart';
import 'package:kubaproject/pages/forgot_password.dart';

/// \class LogIn
/// \brief Widget strony logowania
class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

/// \class _LogInState
/// \brief Stan strony logowania
class _LogInState extends State<LogIn> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true; ///< Ukrywa/pokazuje hasło
  bool _loading = false; ///< Stan ładowania

  /// \brief Obsługuje proces logowania użytkownika
  /// 
  /// Weryfikuje dane, loguje użytkownika w Firebase i zapisuje dane w shared preferences.
  Future<void> _userLogin() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() => _loading = true);
      final emailNorm = _emailController.text.trim().toLowerCase();
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailNorm,
        password: _passwordController.text,
      );
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;
        final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final docSnap = await docRef.get();
        
        final data = docSnap.exists 
            ? docSnap.data() as Map<String, dynamic>
            : {
                'id': uid,
                'name': '',
                'email': user.email ?? emailNorm,
                'image': '',
              };
        
        if (!docSnap.exists) {
          await docRef.set(data, SetOptions(merge: true));
        }

        await SharedPreferenceHelper().saveUserName(data['name'] ?? '');
        await SharedPreferenceHelper().saveUserEmail(data['email'] ?? '');
        await SharedPreferenceHelper().saveUserImage(data['image'] ?? '');
        await SharedPreferenceHelper().saveUserId(uid);
      }
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'user-not-found' => 'Nie znaleziono użytkownika dla tego adresu e-mail.',
        'wrong-password' => 'Podano nieprawidłowe hasło.',
        _ => 'Logowanie nie powiodło się. Spróbuj ponownie.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: kIsWeb ? 500 : double.infinity,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Cześć',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Zaloguj się do aplikacji',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Text(
                  'E-mail',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                TextFormField(
                  validator: (value) => value?.isEmpty ?? true ? 'Podaj adres e-mail' : null,
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'E-mail',
                    prefixIcon: Icon(Icons.mail_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Hasło',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                TextFormField(
                  validator: (value) => value?.isEmpty ?? true ? 'Podaj hasło' : null,
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: 'Hasło',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed:
                          () => setState(() {
                            _obscurePassword = !_obscurePassword;
                          }),
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPassword(),
                        ),
                      );
                    },
                    child: const Text('Zapomniałeś hasła?'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _userLogin,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Zaloguj się'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Nie masz konta? "),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUp(),
                          ),
                        );
                      },
                      child: const Text('Zarejestruj się'),
                    ),
                  ],
                ),
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
