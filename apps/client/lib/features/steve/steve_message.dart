import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Você', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(turn.question),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Steve', style: Theme.of(context).textTheme.titleMedium),
                if (reply.status != 'completed')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      reply.status == 'incomplete'
                          ? 'Resposta incompleta'
                          : 'Pedido não atendido',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  reply.text.isEmpty
                      ? 'Não foi possível concluir a explicação. Você pode reformular a pergunta e tentar novamente.'
                      : reply.text,
                ),
                if (reply.status == 'incomplete')
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Esta resposta não será usada como uma explicação completa na próxima pergunta.',
                    ),
                  ),
                if (reply.sources.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Fontes para estudar'),
                  for (final source in reply.sources)
                    TextButton.icon(
                      icon: const Icon(Icons.open_in_new),
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
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
