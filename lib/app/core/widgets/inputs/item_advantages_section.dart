import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/widgets/inputs/app_form_text_field.dart';
import 'package:flutter/material.dart';

/// A reusable input section allowing users to add and remove multiple
/// advantages/features for an item.
class ItemAdvantagesSection extends StatefulWidget {
  final List<String> advantages;
  final ValueChanged<List<String>> onAdvantagesChanged;

  const ItemAdvantagesSection({
    super.key,
    required this.advantages,
    required this.onAdvantagesChanged,
  });

  @override
  State<ItemAdvantagesSection> createState() => _ItemAdvantagesSectionState();
}

class _ItemAdvantagesSectionState extends State<ItemAdvantagesSection> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addAdvantage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (!widget.advantages.contains(text)) {
      widget.onAdvantagesChanged([...widget.advantages, text]);
    }
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addAdvantage(),
                decoration: buildAppInputDecoration(
                  label: 'أضف ميزة جديدة',
                  icon: Icons.star_outline,
                  hintText: 'مثال: ضمان سنتين، مقاوم للماء، شحن سريع',
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 52,
              child: FilledButton.tonalIcon(
                onPressed: _addAdvantage,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.advantages.isEmpty)
          Text(
            'لا توجد مميزات مضافة بعد',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.advantages.map((advantage) {
              return Chip(
                avatar: const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: AppTheme.success,
                ),
                label: Text(advantage, style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  final updated = List<String>.from(widget.advantages)
                    ..remove(advantage);
                  widget.onAdvantagesChanged(updated);
                },
                backgroundColor: Colors.grey[100],
              );
            }).toList(),
          ),
      ],
    );
  }
}
