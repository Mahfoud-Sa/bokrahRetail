import 'package:flutter/material.dart';

/// Responsive 2-column grid layout for form section cards on desktop,
/// collapsing into a single column on narrow viewports.
class CompanyFormGrid extends StatelessWidget {
  final List<Widget> sections;
  final Widget? footer;

  const CompanyFormGrid({
    super.key,
    required this.sections,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoColumn = constraints.maxWidth >= 900;

        if (!isTwoColumn) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < sections.length; i++) ...[
                sections[i],
                if (i < sections.length - 1) const SizedBox(height: 20),
              ],
              if (footer != null) ...[
                const SizedBox(height: 24),
                footer!,
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (int i = 0; i < sections.length; i += 2) {
          final hasPair = i + 1 < sections.length;
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: sections[i]),
                const SizedBox(width: 20),
                Expanded(
                  child: hasPair ? sections[i + 1] : const SizedBox.shrink(),
                ),
              ],
            ),
          );
          if (i + 2 < sections.length) {
            rows.add(const SizedBox(height: 20));
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...rows,
            if (footer != null) ...[
              const SizedBox(height: 24),
              footer!,
            ],
          ],
        );
      },
    );
  }
}
