/// \file forgot_password.dart
/// \brief Strona resetowania hasła
/// 
/// Umożliwia użytkownikowi wysłanie linku do resetowania hasła na email.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kubaproject/pages/login.dart';

/// \class ForgotPassword
/// \brief Widget strony resetowania hasła
class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

/// \class _ForgotPasswordState
/// \brief Stan strony resetowania hasła
class _ForgotPasswordState extends State<ForgotPassword> {
  final _mailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false; ///< Stan ładowania

  /// \brief Wysyła email z linkiem do resetowania hasła
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _loading = true);
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _mailController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wysłaliśmy wiadomość z linkiem do resetu hasła.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'user-not-found' =>
          'Nie znaleziono użytkownika dla podanego adresu e-mail.',
        'invalid-email' => 'Nieprawidłowy adres e-mail.',
        _ => 'Nie udało się wysłać wiadomości. Spróbuj ponownie.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// \brief Waliduje poprawność adresu email
  /// \param value Wartość do walidacji
  /// \return Komunikat błędu lub null jeśli poprawny
  String? _validateEmail(String? value) {
    if (value?.trim().isEmpty ?? true) return 'Podaj adres e-mail';
    if (!RegExp(r'^\S+@\S+\.\w+$').hasMatch(value!.trim())) {
      return 'Wprowadź poprawny adres e-mail';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Odzyskiwanie hasła')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: kIsWeb ? 500 : double.infinity,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zresetuj hasło',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Podaj adres e-mail powiązany z kontem. Wyślemy link do zmiany hasła.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _mailController,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        hintText: 'Wpisz adres e-mail',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _resetPassword,
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
                                : const Text('Wyślij link resetujący'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Pamiętasz hasło? '),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LogIn()),
                            );
                          },
                          child: const Text('Wróć do logowania'),
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
