import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/components/pixel_avatar.dart';
import '../../design_system/tokens.dart';
import '../learning/external_links.dart';
import 'steve_models.dart';

class SteveMessage extends ConsumerWidget {
  const SteveMessage({super.key, required this.turn});
  final ChatTurn turn;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reply = turn.reply, colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Você',
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: colors.linkInk),
                    ),
                    const SizedBox(height: 8),
                    Text(turn.question),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const PixelAvatar(size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Steve',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                if (reply.status != 'completed')
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      reply.status == 'incomplete'
                          ? 'Resposta incompleta'
                          : 'Pedido não atendido',
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: colors.accentInk),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  reply.text.isEmpty
                      ? 'Não foi possível concluir a explicação. Você pode reformular a pergunta e tentar novamente.'
                      : reply.text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (reply.status == 'incomplete')
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Esta resposta não será usada como uma explicação completa na próxima pergunta.',
                      style: TextStyle(color: colors.muted),
                    ),
                  ),
                if (reply.sources.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Fontes para estudar',
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: colors.muted),
                  ),
                  const SizedBox(height: 8),
                  for (final source in reply.sources)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: Text(source.title),
                        onPressed: () async {
                          final opened = await ref.read(externalLinkProvider)(
                            Uri.parse(source.url),
                          );
                          if (!opened && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Não foi possível abrir a fonte. Tente novamente.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
