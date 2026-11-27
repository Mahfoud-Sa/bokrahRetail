import 'package:flutter/material.dart';

/// Responsive 2-column grid layout for form section cards on desktop,
/// collapsing into a single column on narrow viewports.
class ResponsiveFormGrid extends StatelessWidget {
  final List<Widget> sections;
  final Widget? header;
  final Widget? footer;
  final double breakpoint;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const ResponsiveFormGrid({
    super.key,
    required this.sections,
    this.header,
    this.footer,
    this.breakpoint = 900,
    this.crossAxisSpacing = 20,
    this.mainAxisSpacing = 20,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoColumn = constraints.maxWidth >= breakpoint;
        final items = <Widget>[];

        if (header != null) {
          items.add(header!);
          items.add(SizedBox(height: mainAxisSpacing));
        }

        if (!isTwoColumn) {
          for (int i = 0; i < sections.length; i++) {
            items.add(sections[i]);
            if (i < sections.length - 1) {
              items.add(SizedBox(height: mainAxisSpacing));
            }
          }
        } else {
          for (int i = 0; i < sections.length; i += 2) {
            final hasPair = i + 1 < sections.length;
            items.add(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: sections[i]),
                  SizedBox(width: crossAxisSpacing),
                  Expanded(
                    child: hasPair ? sections[i + 1] : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
            if (i + 2 < sections.length) {
              items.add(SizedBox(height: mainAxisSpacing));
            }
          }
        }

        if (footer != null) {
          items.add(SizedBox(height: mainAxisSpacing + 4));
          items.add(footer!);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: items,
        );
      },
    );
  }
}
