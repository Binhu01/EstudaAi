import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_failure.dart';
import '../../design_system/components/page_heading.dart';
import '../../design_system/components/pixel_avatar.dart';
import '../../design_system/components/study_card.dart';
import '../../design_system/tokens.dart';
import '../auth/session_controller.dart';
import '../learning/learning_controller.dart';
import '../learning/learning_entry.dart';
import '../learning/learning_entry_view.dart';
import '../learning/study_routes.dart';
import '../contests/contest_module_actions.dart';
import 'steve_controller.dart';
import 'steve_message.dart';

class SteveScreen extends ConsumerWidget {
  const SteveScreen({
    super.key,
    required this.topicId,
    this.area = LearningArea.freeStudy,
  });
  final String topicId;
  final LearningArea area;
  @override
  Widget build(BuildContext context, WidgetRef ref) => LearningEntryView(
    topicId: topicId,
    area: area,
    builder: (entry) {
      final topic = entry.topic;
      final session = ref.watch(sessionProvider),
          learning = ref.watch(learningProvider);
      final chatContext = session.isAuthenticated
          ? (
              topicId: topic.id,
              userId: session.profile!.id,
              sessionGeneration: session.generation,
              topicGeneration: learning.generation,
            )
          : null;
      return _Chat(
        key: ValueKey(chatContext ?? (topic.id, session.generation)),
        entry: entry,
        chatContext: chatContext,
      );
    },
  );
}

class _Chat extends ConsumerStatefulWidget {
  const _Chat({super.key, required this.entry, this.chatContext});
  final LearningEntry entry;
  final SteveContext? chatContext;
  @override
  ConsumerState<_Chat> createState() => _ChatState();
}

class _ChatState extends ConsumerState<_Chat> {
  final _message = TextEditingController();
  final _focus = FocusNode();
  @override
  void dispose() {
    _message.clear();
    _message.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final key = widget.chatContext;
    if (key == null) return;
    final before = ref.read(steveProvider(key)).turns.length;
    await ref.read(steveProvider(key).notifier).send(_message.text);
    if (!mounted) return;
    final next = ref.read(steveProvider(key));
    if (next.turns.length > before) _message.clear();
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.chatContext, colors = AppColors.of(context);
    final state = key == null ? null : ref.watch(steveProvider(key));
    final entry = widget.entry, suggestions = entry.suggestions;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600 ? 20 : 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeading(
                  eyebrow: 'PERGUNTE. ENTENDA. APRENDA.',
                  title: 'Steve',
                  description: entry.area == LearningArea.contest
                      ? 'Seu companheiro de estudo · Concursos · ${entry.courseTitle}'
                      : 'Seu companheiro de estudo · Estudo livre',
                  trailing: MediaQuery.sizeOf(context).width < 600
                      ? null
                      : Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const PixelAvatar(size: 64),
                        ),
                ),
                const SizedBox(height: 28),
                StudyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'CONTEXTO DA CONVERSA',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: colors.muted),
                      ),
                      const SizedBox(height: 16),
                      LearningEntrySelector(
                        entry: entry,
                        action: StudyAction.steve,
                      ),
                      if (entry.area == LearningArea.contest) ...[
                        const SizedBox(height: 20),
                        ContestModuleActions(
                          entry: entry,
                          selected: StudyAction.steve,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${entry.topic.subject} · ${entry.topic.title}',
                          style: TextStyle(color: colors.muted),
                        ),
                        if (entry.disciplineId == 'redacao')
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              'Apoio formativo à escrita, sem nota oficial.',
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (key == null)
                  StudyCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: colors.primary,
                          size: 28,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Uma dúvida pode abrir um caminho.',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Entre na sua conta para conversar com o Steve.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: colors.muted),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => context.go('/conta'),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Entrar para conversar'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context.go(
                            StudyRoutes.path(entry, StudyAction.lessons),
                          ),
                          child: const Text('Ver videoaulas deste assunto'),
                        ),
                      ],
                    ),
                  )
                else ...[
                  if (state!.turns.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'O que você quer descobrir hoje?',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Comece com uma sugestão ou escreva sua própria pergunta.',
                            style: TextStyle(color: colors.muted),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final suggestion in suggestions)
                                OutlinedButton(
                                  onPressed: state.pending
                                      ? null
                                      : () {
                                          _message.text = suggestion;
                                          _focus.requestFocus();
                                        },
                                  child: Text(suggestion),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  for (final turn in state.turns) SteveMessage(turn: turn),
                  if (state.pending)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: StudyCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Você',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(color: colors.muted),
                              ),
                              const SizedBox(height: 8),
                              Text(state.pendingQuestion!),
                              const SizedBox(height: 20),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text('Steve está pensando…'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colors.errorSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            safeFailureMessage(state.error!.code),
                            style: TextStyle(color: colors.errorInk),
                          ),
                        ),
                      ),
                    ),
                  if (state.error?.resetAt != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Cota renovada em ${_when(state.error!.resetAt!)}',
                        style: TextStyle(color: colors.muted),
                      ),
                    ),
                  if (state.quota != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '${state.quota!.remaining} mensagens disponíveis hoje',
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: colors.muted),
                      ),
                    ),
                  const SizedBox(height: 16),
                  StudyCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          key: const ValueKey('steve-message-field'),
                          controller: _message,
                          focusNode: _focus,
                          enabled: !state.pending,
                          minLines: 2,
                          maxLines: 6,
                          maxLength: 2000,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.send,
                          decoration: const InputDecoration(
                            labelText: 'Sua pergunta',
                            hintText: 'O que você gostaria de entender melhor?',
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              key: const ValueKey('steve-send'),
                              onPressed: state.pending ? null : _send,
                              icon: const Icon(Icons.arrow_upward_rounded),
                              label: Text(
                                state.pending
                                    ? 'Aguarde a resposta'
                                    : 'Enviar pergunta',
                              ),
                            ),
                            OutlinedButton.icon(
                              key: const ValueKey('steve-new'),
                              onPressed: () {
                                ref
                                    .read(steveProvider(key).notifier)
                                    .newConversation();
                                _message.clear();
                              },
                              icon: const Icon(Icons.add_comment_outlined),
                              label: const Text('Nova conversa'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'As respostas são geradas por IA e podem conter erros. Confira as fontes e os passos da explicação.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.muted),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Uma pergunta enviada pode consumir o limite diário mesmo se a resposta não chegar. Nova conversa interrompe o pedido.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.muted),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _when(DateTime utc) {
    final d = utc.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} às ${two(d.hour)}:${two(d.minute)}';
  }
}
