import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_failure.dart';
import '../../design_system/components/pixel_avatar.dart';
import '../learning/learning_controller.dart';
import 'session_controller.dart';

enum _Mode { login, register, reset }

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  _Mode _mode = _Mode.login;
  bool _submitted = false, _resetSent = false, _submitting = false;
  @override
  void dispose() {
    _email.dispose();
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !(_form.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _submitting = true;
      _submitted = true;
      _resetSent = false;
    });
    final controller = ref.read(sessionProvider.notifier);
    try {
      switch (_mode) {
        case _Mode.login:
          await controller.login(_email.text, _password.text);
        case _Mode.register:
          await controller.register(_email.text, _password.text);
        case _Mode.reset:
          await controller.resetPassword(_email.text);
      }
      if (mounted &&
          _mode == _Mode.reset &&
          ref.read(sessionProvider).error == null) {
        setState(() => _resetSent = true);
      }
    } finally {
      if (mounted) {
        _password.clear();
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider),
        controller = ref.read(sessionProvider.notifier);
    ref.listen(sessionProvider, (previous, next) {
      if (next.status == SessionStatus.signedOut) {
        _password.clear();
      }
    });
    final busy = _submitting || session.status == SessionStatus.authenticating;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: PixelAvatar(size: 64),
                ),
                const SizedBox(height: 24),
                Text(
                  'Sua conta',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Entre para conversar com o Steve. Aulas e desafios continuam disponíveis sem uma conta.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Por enquanto, ao fechar ou recarregar o aplicativo, será preciso entrar novamente.',
                ),
                const SizedBox(height: 24),
                if (session.isAuthenticated) ...[
                  Text(
                    'Você está conectado',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (session.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(safeFailureMessage(session.error?.code)),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.go(
                      '/aprender/${ref.read(learningProvider).topicId}',
                    ),
                    child: const Text('Retomar os estudos'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: controller.signOut,
                    child: const Text('Sair da conta'),
                  ),
                ] else if (session.status ==
                    SessionStatus.refreshUnavailable) ...[
                  const Text(
                    'Falta confirmar seu acesso. Tente novamente para concluir a entrada.',
                  ),
                  const SizedBox(height: 12),
                  Text(safeFailureMessage(session.error?.code)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: busy ? null : controller.retryProfile,
                    child: const Text('Concluir acesso'),
                  ),
                  TextButton(
                    onPressed: controller.signOut,
                    child: const Text('Entrar novamente'),
                  ),
                ] else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in const [
                        (_Mode.login, 'Entrar'),
                        (_Mode.register, 'Criar conta'),
                        (_Mode.reset, 'Recuperar senha'),
                      ])
                        ChoiceChip(
                          label: Text(item.$2),
                          selected: _mode == item.$1,
                          onSelected: busy
                              ? null
                              : (_) => setState(() {
                                  _mode = item.$1;
                                  _password.clear();
                                  _submitted = false;
                                  _resetSent = false;
                                }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          key: const ValueKey('email-field'),
                          controller: _email,
                          enabled: !busy,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: _mode == _Mode.reset
                              ? TextInputAction.done
                              : TextInputAction.next,
                          maxLength: 254,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            return email.length <= 254 &&
                                    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                        .hasMatch(email)
                                ? null
                                : 'Informe um e-mail válido.';
                          },
                          onFieldSubmitted: (_) {
                            if (_mode == _Mode.reset) {
                              _submit();
                            }
                          },
                        ),
                        if (_mode != _Mode.reset) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const ValueKey('password-field'),
                            controller: _password,
                            enabled: !busy,
                            obscureText: true,
                            autocorrect: false,
                            enableSuggestions: false,
                            maxLength: 128,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              helperText: _mode == _Mode.register
                                  ? 'Use de 8 a 128 caracteres.'
                                  : null,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe sua senha.';
                              }
                              if (_mode == _Mode.register &&
                                  (value.length < 8 || value.trim().isEmpty)) {
                                return 'Use pelo menos 8 caracteres.';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),
                        ],
                        if (_submitted && session.error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                safeFailureMessage(session.error?.code),
                              ),
                            ),
                          ),
                        if (_resetSent)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Se houver uma conta com esse e-mail, você receberá um link de recuperação.',
                            ),
                          ),
                        const SizedBox(height: 16),
                        FilledButton(
                          key: const ValueKey('account-submit'),
                          onPressed: busy ? null : _submit,
                          child: Text(
                            busy
                                ? 'Aguarde…'
                                : switch (_mode) {
                                    _Mode.login => 'Entrar na conta',
                                    _Mode.register => 'Criar minha conta',
                                    _Mode.reset => 'Enviar link de recuperação',
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Voltar ao estudo livre'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
