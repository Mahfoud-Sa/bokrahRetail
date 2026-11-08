import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import 'patterns.dart';

class PatternsPage extends StatefulWidget {
  const PatternsPage({super.key});

  @override
  State<PatternsPage> createState() => _PatternsPageState();
}

class _PatternsPageState extends State<PatternsPage> {
  bool? _overrideArabic;

  @override
  Widget build(BuildContext context) {
    final systemAr = Directionality.of(context) == TextDirection.rtl;
    final isAr = _overrideArabic ?? systemAr;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: isAr ? 'رجوع' : 'Back',
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                try {
                  context.go('/home');
                } catch (_) {}
              }
            },
          ),
          title: Text(isAr ? 'أنماط التصميم' : 'Design Patterns'),
          actions: [
            TextButton(
              onPressed: () => setState(() => _overrideArabic = !isAr),
              child: Text(
                isAr ? 'English' : 'العربية',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(BkSpace.xl),
              child: PatternsCatalogue(arabic: isAr),
            ),
          ),
        ),
      ),
    );
  }
}
