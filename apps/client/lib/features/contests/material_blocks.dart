import 'package:flutter/material.dart';

import 'contest_models.dart';
import 'contest_widgets.dart';

class MaterialBlocks extends StatelessWidget {
  const MaterialBlocks({super.key, required this.blocks});
  final List<MaterialBlock> blocks;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final block in blocks)
        MaterialSection(
          title: block.title,
          children: switch (block) {
            TextBlock() => [
              SelectableText(block.text, semanticsLabel: block.text),
            ],
            ListBlock() => [StudyBullets(block.items)],
            ExampleBlock() => [
              Text(block.problem),
              const SizedBox(height: 12),
              for (var i = 0; i < block.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${i + 1}. ${block.steps[i]}'),
                ),
              Text(
                'Resposta: ${block.answer}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('Confira: ${block.check}'),
            ],
            FormulaBlock() => [
              SelectableText(
                block.expression,
                semanticsLabel: block.expression,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              StudyBullets([
                for (final v in block.variables)
                  '${v.name}: ${v.meaning} (${v.unit})',
              ]),
              const Text(
                'Condições de uso',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              StudyBullets(block.conditions),
            ],
            TableBlock() => [_MaterialTable(block: block)],
          },
        ),
    ],
  );
}

class _MaterialTable extends StatefulWidget {
  const _MaterialTable({required this.block});
  final TableBlock block;
  @override
  State<_MaterialTable> createState() => _MaterialTableState();
}

class _MaterialTableState extends State<_MaterialTable> {
  final controller = ScrollController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('A tabela pode ser rolada horizontalmente.'),
      const SizedBox(height: 12),
      Scrollbar(
        controller: controller,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: controller,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 240.0 * widget.block.columns.length,
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(240),
              border: TableBorder.all(color: Theme.of(context).dividerColor),
              children: [
                TableRow(
                  children: [
                    for (final column in widget.block.columns)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Semantics(
                          header: true,
                          child: Text(
                            column,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
                for (final row in widget.block.rows)
                  TableRow(
                    children: [
                      for (final cell in row)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(cell),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(widget.block.caption),
    ],
  );
}
