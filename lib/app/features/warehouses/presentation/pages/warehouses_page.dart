import 'package:flutter/material.dart';

class WarehousesPage extends StatelessWidget {
  const WarehousesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المستودعات'),
          backgroundColor: const Color(0xFF2E7D64),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('صفحة المستودعات قيد التطوير')),
      ),
    );
  }
}
