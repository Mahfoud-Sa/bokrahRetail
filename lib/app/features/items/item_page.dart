import 'package:flutter/material.dart';

class Item {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;

  Item({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
  });
}

class ItemPage extends StatefulWidget {
  const ItemPage({super.key});

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _imageCtrl = TextEditingController();

  final List<Item> _items = [];

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  void _addItem() {
    if (!_formKey.currentState!.validate()) return;

    final id = _idCtrl.text.isNotEmpty
        ? _idCtrl.text
        : DateTime.now().millisecondsSinceEpoch.toString();
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final imageUrl = _imageCtrl.text.trim().isEmpty
        ? null
        : _imageCtrl.text.trim();

    final item = Item(id: id, name: name, price: price, imageUrl: imageUrl);

    setState(() {
      _items.insert(0, item);
      _idCtrl.clear();
      _nameCtrl.clear();
      _priceCtrl.clear();
      _imageCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('العناصر')),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _idCtrl,
                      decoration: const InputDecoration(
                        labelText: 'معرّف العنصر (اختياري)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم العنصر',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'الرجاء إدخال اسم'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'السعر'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'الرجاء إدخال السعر';
                        }
                        if (double.tryParse(v.trim()) == null) {
                          return 'الرجاء إدخال رقم صالح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _imageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'رابط الصورة (اختياري)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة عنصر'),
                            onPressed: _addItem,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              const Divider(),

              Expanded(
                child: _items.isEmpty
                    ? const Center(child: Text('لا توجد عناصر بعد'))
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final it = _items[index];
                          return Card(
                            child: ListTile(
                              leading: it.imageUrl != null
                                  ? Image.network(
                                      it.imageUrl!,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.image_not_supported),
                                    )
                                  : const CircleAvatar(
                                      child: Icon(Icons.inventory_2),
                                    ),
                              title: Text(it.name),
                              subtitle: Text('ID: ${it.id}'),
                              trailing: Text(it.price.toStringAsFixed(2)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
