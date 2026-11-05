import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/plant.dart';
import '../routes.dart';
import '../state/plant_store.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';
import '../widgets/plant_illustration.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscure = true;
  bool _loading = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _error = null;
    });
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _loading = true);
    final PlantStore store = context.read<PlantStore>();
    String? error;
    try {
      error = await store.login(_email.text, _password.text);
    } catch (_) {
      error = 'Terjadi masalah saat masuk. Coba lagi.';
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pushReplacementNamed(Routes.home);
      return;
    }
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  Widget _hero({required bool wide}) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      color: Palette.paperDeep,
      padding: EdgeInsets.symmetric(vertical: wide ? 32 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: wide ? 220 : 150,
            width: wide ? 220 : 150,
            child: const PlantIllustration(kind: PlantKind.leafy),
          ),
          const SizedBox(height: 8),
          Text('Semai', style: AppText.display(40, letterSpacing: -0.6)),
        ],
      ),
    );
  }

  Widget _form(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      autovalidateMode: _submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Masuk', style: text.headlineMedium),
          const SizedBox(height: 6),
          const Text(
            'Lihat jadwal siram tanamanmu hari ini.',
            style: TextStyle(color: Palette.inkSoft, height: 1.4),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: Validators.email,
            onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            focusNode: _passwordFocus,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Kata sandi',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: Validators.password,
            onFieldSubmitted: (_) {
              if (!_loading) _submit();
            },
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 16),
            InlineMessage(message: _error!),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Palette.ink,
                    ),
                  )
                : const Text('Masuk'),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Palette.paperDeep,
              borderRadius: AppTheme.radius,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Akun demo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                SelectableText(
                  'Email: ${PlantStore.demoEmail}\nKata sandi: ${PlantStore.demoPassword}',
                  style: TextStyle(color: Palette.inkSoft, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 720;
            if (wide) {
              return Row(
                children: <Widget>[
                  Expanded(flex: 5, child: SizedBox.expand(child: _hero(wide: true))),
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: _form(context),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _hero(wide: false),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: _form(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
