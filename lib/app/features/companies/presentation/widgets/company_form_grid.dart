import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';

/// Responsive 2-column grid layout for form section cards on desktop,
/// collapsing into a single column on narrow viewports.
class CompanyFormGrid extends StatelessWidget {
  final List<Widget> sections;
  final Widget? footer;

  const CompanyFormGrid({super.key, required this.sections, this.footer});

  @override
  Widget build(BuildContext context) {
    return ResponsiveFormGrid(sections: sections, footer: footer);
  }
}
