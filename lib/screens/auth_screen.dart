import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Email + password sign-in / sign-up. (Google & Apple OAuth come later, once
/// the provider keys are configured in the Supabase dashboard.)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Names are required when creating an account.
    if (_isSignUp &&
        (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty)) {
      setState(() => _message = 'Please enter your first and last name.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    final auth = Supabase.instance.client.auth;
    try {
      if (_isSignUp) {
        final first = _firstName.text.trim();
        final last = _lastName.text.trim();
        await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {
            'first_name': first,
            'last_name': last,
            'full_name': '$first $last',
          },
        );
        setState(() => _message =
            'Account created. If email confirmation is on, check your inbox.');
      } else {
        await auth.signInWithPassword(
            email: _email.text.trim(), password: _password.text);
      }
    } on AuthException catch (e) {
      setState(() => _message = e.message);
    } catch (e) {
      setState(() => _message = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Instant access with no account (Supabase anonymous sign-in).
  Future<void> _guest() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.auth.signInAnonymously();
    } on AuthException catch (e) {
      setState(() => _message = e.message);
    } catch (e) {
      setState(() => _message = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('VerbaPrep',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Capture words. Master them. Ace the SAT.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),
                if (_isSignUp) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _firstName,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                              labelText: 'First name',
                              border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _lastName,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                              labelText: 'Last name',
                              border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isSignUp ? 'Sign up' : 'Sign in'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(_isSignUp
                      ? 'Have an account? Sign in'
                      : 'New here? Create an account'),
                ),
                const SizedBox(height: 4),
                Row(children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('or'),
                  ),
                  Expanded(child: Divider()),
                ]),
                const SizedBox(height: 4),
                OutlinedButton(
                  onPressed: _busy ? null : _guest,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Continue as guest'),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(_message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
