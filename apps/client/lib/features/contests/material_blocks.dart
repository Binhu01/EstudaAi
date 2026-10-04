import 'package:flutter/material.dart';

import '../../design_system/tokens.dart';
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
              SelectableText(
                block.text,
                semanticsLabel: block.text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            ListBlock() => [StudyBullets(block.items)],
            ExampleBlock() => [_WorkedExample(block: block)],
            FormulaBlock() => [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.of(context).primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  block.expression,
                  semanticsLabel: block.expression,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 20),
              StudyBullets([
                for (final variable in block.variables)
                  '${variable.name}: ${variable.meaning} (${variable.unit})',
              ]),
              const Text(
                'Condições de uso',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              StudyBullets(block.conditions),
            ],
            TableBlock() => [_MaterialTable(block: block)],
          },
        ),
    ],
  );
}

class _WorkedExample extends StatelessWidget {
  const _WorkedExample({required this.block});
  final ExampleBlock block;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(block.problem, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
        for (var i = 0; i < block.steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '${i + 1}.',
                    style: TextStyle(
                      color: colors.linkInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(child: Text(block.steps[i])),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resposta: ${block.answer}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text('Confira: ${block.check}'),
            ],
          ),
        ),
      ],
    );
  }
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
      Text(
        'A tabela pode ser rolada horizontalmente.',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppColors.of(context).muted),
      ),
      const SizedBox(height: 16),
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
              border: TableBorder.all(color: AppColors.of(context).border),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: AppColors.of(context).primarySoft,
                  ),
                  children: [
                    for (final column in widget.block.columns)
                      Padding(
                        padding: const EdgeInsets.all(16),
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
                          padding: const EdgeInsets.all(16),
                          child: Text(cell),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text(widget.block.caption),
    ],
  );
}
