import 'package:flutter/material.dart';
import '../models/medicine.dart';
import 'database_helper.dart';
import 'pharmacy_service.dart';

class ManageMedicinesScreen extends StatefulWidget {
  const ManageMedicinesScreen({super.key});

  @override
  State<ManageMedicinesScreen> createState() => _ManageMedicinesScreenState();
}

class _ManageMedicinesScreenState extends State<ManageMedicinesScreen> {
  List<Medicine> _medicines = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _refreshMedicines();
  }

  Future<void> _refreshMedicines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await DatabaseHelper.instance.getAllMedicines();
      setState(() {
        _medicines = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddEditMedicineDialog(BuildContext context, [Medicine? existing]) {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final categoryCtrl = TextEditingController(text: existing?.category ?? '');
    final priceCtrl = TextEditingController(
      text: existing?.price.toString() ?? '',
    );
    final qtyCtrl = TextEditingController(
      text: existing?.stockQuantity?.toString() ?? '',
    );
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Medicine' : 'Add Medicine'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Medicine Name'),
              ),
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (Ksh)'),
              ),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1B8F4A),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final category = categoryCtrl.text.trim().isNotEmpty
                  ? categoryCtrl.text.trim()
                  : 'General';
              final price = double.tryParse(priceCtrl.text) ?? 0.0;
              final quantity = int.tryParse(qtyCtrl.text) ?? 1;
              final description = descCtrl.text.trim().isNotEmpty
                  ? descCtrl.text.trim()
                  : 'Local storage medicine';

              if (name.isNotEmpty && price > 0) {
                final newMed = Medicine(
                  id:
                      existing?.id ??
                      'med_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  category: category,
                  price: price,
                  stockQuantity: quantity,
                  description: description,
                  rating: existing?.rating ?? 0.0,
                  imageUrl: existing?.imageUrl,
                );

                try {
                  if (isEditing) {
                    await PharmacyService.instance.updateMedicine(newMed);
                  } else {
                    await PharmacyService.instance.addMedicine(newMed);
                  }

                  if (!mounted) return;
                  Navigator.pop(ctx);
                  _refreshMedicines(); // Automatically updates the UI immediately
                } catch (e) {
                  debugPrint('Error saving: $e');
                }
              }
            },
            child: Text(isEditing ? 'Update' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMedicine(String? id) async {
    if (id == null) return;
    try {
      await PharmacyService.instance.deleteMedicine(id);
      _refreshMedicines(); // Automatically updates the UI immediately
    } catch (e) {
      debugPrint('Error deleting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local SQLite DB')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditMedicineDialog(context),
        backgroundColor: const Color(0xFF1B8F4A),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1B8F4A)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load data:\n$_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshMedicines,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_medicines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storage_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No local medicines found.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showAddEditMedicineDialog(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1B8F4A),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add First Medicine'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _medicines.length,
      itemBuilder: (context, index) {
        final medicine = _medicines[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEAF7EF),
              child: Icon(Icons.medication, color: Color(0xFF1B8F4A)),
            ),
            title: Text(
              medicine.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Ksh ${medicine.price.toStringAsFixed(0)} • ${medicine.category}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () =>
                      _showAddEditMedicineDialog(context, medicine),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _deleteMedicine(medicine.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
