import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_failure.dart';
import '../../design_system/components/pixel_avatar.dart';
import '../auth/session_controller.dart';
import '../learning/learning_controller.dart';
import '../learning/learning_screen.dart';
import '../learning/study_catalog.dart';
import 'steve_controller.dart';
import 'steve_message.dart';

class SteveScreen extends ConsumerWidget {
  const SteveScreen({super.key, required this.topicId});
  final String topicId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => StudyTopicView(
    topicId: topicId,
    builder: (catalog, topic) {
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
        catalog: catalog,
        topic: topic,
        chatContext: chatContext,
      );
    },
  );
}

class _Chat extends ConsumerStatefulWidget {
  const _Chat({
    super.key,
    required this.catalog,
    required this.topic,
    this.chatContext,
  });
  final LearningCatalog catalog;
  final StudyTopic topic;
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
    final key = widget.chatContext;
    final state = key == null ? null : ref.watch(steveProvider(key));
    final suggestions = [
      switch (widget.topic.id) {
        'porcentagem' => 'Como calcular um desconto de 20%?',
        'interpretacao-texto' =>
          'Como encontrar a ideia principal de um texto?',
        _ => 'Qual é a diferença entre cadeia e teia alimentar?',
      },
      'Como usar as aulas e os desafios?',
    ];
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: PixelAvatar(size: 64),
                ),
                const SizedBox(height: 16),
                Text('Steve', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                const Text('Seu companheiro de estudo · Estudo livre'),
                const SizedBox(height: 24),
                TopicSelector(
                  catalog: widget.catalog,
                  topicId: widget.topic.id,
                  routePrefix: '/steve',
                ),
                const SizedBox(height: 24),
                if (key == null) ...[
                  const Text('Entre na sua conta para conversar com o Steve.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/conta'),
                    child: const Text('Entrar para conversar'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/aprender/${widget.topic.id}'),
                    child: const Text('Ver videoaulas deste assunto'),
                  ),
                ] else ...[
                  if (state!.turns.isEmpty) ...[
                    const Text('O que você quer descobrir hoje?'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
                  for (final turn in state.turns) SteveMessage(turn: turn),
                  if (state.pending)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(state.pendingQuestion!),
                            const SizedBox(height: 8),
                            const Text('Steve está pensando…'),
                          ],
                        ),
                      ),
                    ),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(safeFailureMessage(state.error!.code)),
                      ),
                    ),
                  if (state.error?.resetAt != null)
                    Text('Cota renovada em ${_when(state.error!.resetAt!)}'),
                  if (state.quota != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '${state.quota!.remaining} mensagens disponíveis hoje',
                      ),
                    ),
                  const SizedBox(height: 16),
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
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const ValueKey('steve-send'),
                    onPressed: state.pending ? null : _send,
                    icon: const Icon(Icons.send_outlined),
                    label: Text(
                      state.pending ? 'Aguarde a resposta' : 'Enviar pergunta',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const ValueKey('steve-new'),
                    onPressed: () {
                      ref.read(steveProvider(key).notifier).newConversation();
                      _message.clear();
                    },
                    icon: const Icon(Icons.add_comment_outlined),
                    label: const Text('Nova conversa'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'As respostas são geradas por IA e podem conter erros. Confira as fontes e os passos da explicação.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Uma pergunta enviada pode consumir o limite diário mesmo se a resposta não chegar. Nova conversa interrompe o pedido.',
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
