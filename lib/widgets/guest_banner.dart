import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shown only when the signed-in user is anonymous (a guest). Lets them attach
/// an email + password to keep their progress — Supabase links it to the same
/// user ID, so all captured words, reviews, and scores are preserved.
class GuestBanner extends StatelessWidget {
  const GuestBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, _) {
        final isGuest = auth.currentUser?.isAnonymous ?? false;
        if (!isGuest) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        return Material(
          color: scheme.primaryContainer,
          child: InkWell(
            onTap: () => _showUpgradeDialog(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.bookmark_added_outlined,
                      color: scheme.onPrimaryContainer, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "You're a guest — save your progress",
                      style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text('Save',
                      style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold)),
                  Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> _showUpgradeDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const _UpgradeDialog(),
  );
}

class _UpgradeDialog extends StatefulWidget {
  const _UpgradeDialog();
  @override
  State<_UpgradeDialog> createState() => _UpgradeDialogState();
}

class _UpgradeDialogState extends State<_UpgradeDialog> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_email.text.trim().isEmpty || _password.text.length < 6) {
      setState(() => _message = 'Enter an email and a password (6+ characters).');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final first = _first.text.trim();
      final last = _last.text.trim();
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          email: _email.text.trim(),
          password: _password.text,
          data: {
            if (first.isNotEmpty) 'first_name': first,
            if (last.isNotEmpty) 'last_name': last,
            if (first.isNotEmpty || last.isNotEmpty)
              'full_name': '$first $last'.trim(),
          },
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Progress saved — you can now sign in with that email.'),
      ));
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
    return AlertDialog(
      title: const Text('Save your progress'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Add an email and password to keep your words and scores. '
            'Everything you have so far stays.',
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _first,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'First name'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _last,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Last name'),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(_message!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
