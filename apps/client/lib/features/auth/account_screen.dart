import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_failure.dart';
import '../../design_system/components/page_heading.dart';
import '../../design_system/components/study_card.dart';
import '../../design_system/tokens.dart';
import '../learning/learning_controller.dart';
import '../learning/learning_catalog_providers.dart';
import '../learning/learning_entry.dart';
import '../learning/study_routes.dart';
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
    if (_submitting || !(_form.currentState?.validate() ?? false)) return;
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

  void _openStudy(StudyAction action) {
    final selection = ref.read(learningProvider);
    final entry = ref
        .read(learningEntryProvider(selection.topicId))
        .asData
        ?.value;
    context.go(
      entry == null
          ? (selection.area == LearningArea.contest ? '/concursos' : '/')
          : StudyRoutes.path(entry, action),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider),
        controller = ref.read(sessionProvider.notifier),
        colors = AppColors.of(context);
    ref.listen(sessionProvider, (previous, next) {
      if (next.status == SessionStatus.signedOut) _password.clear();
    });
    final busy = _submitting || session.status == SessionStatus.authenticating;
    final formPanel = StudyCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (session.isAuthenticated) ...[
            Icon(
              Icons.check_circle_outline_rounded,
              color: colors.success,
              size: 36,
            ),
            const SizedBox(height: 16),
            Text(
              'Você está conectado',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Continue seu estudo ou converse com o Steve sobre o assunto escolhido.',
              style: TextStyle(color: colors.muted),
            ),
            if (session.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _AccountNotice(
                  message: safeFailureMessage(session.error?.code),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openStudy(StudyAction.steve),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Conversar com o Steve'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _openStudy(StudyAction.material),
              child: const Text('Retomar os estudos'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: controller.signOut,
              child: const Text('Sair da conta'),
            ),
          ] else if (session.status == SessionStatus.refreshUnavailable) ...[
            Icon(Icons.lock_clock_outlined, color: colors.accentInk, size: 32),
            const SizedBox(height: 16),
            Text(
              'Confirme seu acesso',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Falta confirmar seu acesso. Tente novamente para concluir a entrada.',
            ),
            const SizedBox(height: 16),
            _AccountNotice(message: safeFailureMessage(session.error?.code)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: busy ? null : controller.retryProfile,
              child: const Text('Concluir acesso'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: controller.signOut,
              child: const Text('Entrar novamente'),
            ),
          ] else ...[
            Text(switch (_mode) {
              _Mode.login => 'Bom ter você por aqui.',
              _Mode.register => 'Seu próximo passo começa aqui.',
              _Mode.reset => 'Vamos recuperar seu acesso.',
            }, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
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
                      prefixIcon: Icon(Icons.alternate_email_rounded),
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
                      if (_mode == _Mode.reset) _submit();
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
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        helperText: _mode == _Mode.register
                            ? 'Use de 8 a 128 caracteres.'
                            : null,
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
                      child: _AccountNotice(
                        message: safeFailureMessage(session.error?.code),
                      ),
                    ),
                  if (_resetSent)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: _AccountNotice(
                        message: 'Se houver uma conta com esse e-mail, você receberá um link de recuperação.',
                        success: true,
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
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: colors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Por enquanto, ao fechar ou recarregar o aplicativo, será preciso entrar novamente.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600 ? 20 : 40,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= 820 &&
                    MediaQuery.textScalerOf(context).scale(16) <= 22;
                final overview = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PageHeading(
                      eyebrow: 'SEU ESPAÇO DE ESTUDO',
                      title: 'Sua conta',
                      description:
                          'Um lugar para acompanhar o que você aprende.',
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Entre para conversar com o Steve. Aulas e desafios continuam disponíveis sem uma conta.',
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: colors.muted),
                    ),
                  ],
                );
                const benefits = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AccountBenefit(
                      icon: Icons.flag_outlined,
                      title: 'Seu ritmo, sua meta',
                      description: 'Acompanhe as questões confirmadas e sua atividade diária.',
                    ),
                    SizedBox(height: 24),
                    _AccountBenefit(
                      icon: Icons.auto_stories_outlined,
                      title: 'Aprenda com cada tentativa',
                      description: 'Guarde os erros para revisar as questões com atenção.',
                    ),
                    SizedBox(height: 24),
                    _AccountBenefit(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Estude com o Steve',
                      description: 'Faça perguntas sobre o assunto que você está estudando.',
                    ),
                  ],
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                overview,
                                const SizedBox(height: 32),
                                benefits,
                              ],
                            ),
                          ),
                          const SizedBox(width: 56),
                          Expanded(child: formPanel),
                        ],
                      )
                    else ...[
                      overview,
                      const SizedBox(height: 32),
                      formPanel,
                      const SizedBox(height: 32),
                      benefits,
                    ],
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Voltar ao estudo livre'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountBenefit extends StatelessWidget {
  const _AccountBenefit({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title, description;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 22, color: colors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(color: colors.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountNotice extends StatelessWidget {
  const _AccountNotice({required this.message, this.success = false});
  final String message;
  final bool success;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: success ? colors.successSoft : colors.errorSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: success ? colors.successInk : colors.errorInk,
          ),
        ),
      ),
    );
  }
}
