/// \file signup.dart
/// \brief Strona rejestracji nowego użytkownika
/// 
/// Umożliwia utworzenie nowego konta w aplikacji.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kubaproject/pages/home.dart';
import 'package:kubaproject/pages/login.dart';

import '../services/database.dart';
import '../services/shared_pref.dart';

/// \class SignUp
/// \brief Widget strony rejestracji
class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

/// \class _SignUpState
/// \brief Stan strony rejestracji
class _SignUpState extends State<SignUp> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true; ///< Ukrywa/pokazuje hasło
  bool _loading = false; ///< Stan ładowania

  /// \brief Obsługuje proces rejestracji nowego użytkownika
  /// 
  /// Tworzy konto w Firebase Auth, zapisuje dane w Firestore i shared preferences.
  Future<void> _registration() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _loading = true);
        final emailNorm = _emailController.text.trim().toLowerCase();
        final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
          emailNorm,
        );
        if (methods.isNotEmpty) {
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'Email already in use',
          );
        }

        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: emailNorm,
              password: _passwordController.text,
            );
        final id = userCredential.user!.uid;
        final userName = _nameController.text.trim();

        await SharedPreferenceHelper().saveUserName(userName);
        await SharedPreferenceHelper().saveUserEmail(emailNorm);
        await SharedPreferenceHelper().saveUserImage('');
        await SharedPreferenceHelper().saveUserId(id);

        await DatabaseMethods().addUserDetails({
          "name": userName,
          "email": emailNorm,
          "id": id,
          "image": '',
        }, id);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rejestracja zakończona sukcesem")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        final msg = switch (e.code) {
          'weak-password' => 'Hasło jest zbyt słabe.',
          'email-already-in-use' =>
            'Konto dla podanego adresu e-mail już istnieje.',
          'invalid-email' => 'Nieprawidłowy adres e-mail.',
          _ => 'Rejestracja nie powiodła się. Spróbuj ponownie.',
        };
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
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
                  'Utwórz konto',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wprowadź dane, aby się zarejestrować',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Text(
                  'Imię i nazwisko',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                TextFormField(
                  validator:
                      (value) =>
                          value?.isEmpty ?? true
                              ? "Podaj imię i nazwisko"
                              : null,
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: "Imię i nazwisko",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'E-mail',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                TextFormField(
                  validator:
                      (value) =>
                          value?.isEmpty ?? true ? "Podaj adres e-mail" : null,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: "E-mail",
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
                  validator: (value) {
                    if (value?.isEmpty ?? true) return "Podaj hasło";
                    if (value!.length < 6)
                      return "Hasło musi mieć co najmniej 6 znaków";
                    return null;
                  },
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: "Hasło",
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _registration,
                    child:
                        _loading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text('Zarejestruj się'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Masz już konto? "),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LogIn(),
                          ),
                        );
                      },
                      child: const Text('Zaloguj się'),
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
