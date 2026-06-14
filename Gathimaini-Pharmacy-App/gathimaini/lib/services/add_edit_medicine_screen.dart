import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sqlite_medicine.dart';
import 'medicine_provider.dart';

class AddEditMedicineScreen extends StatefulWidget {
  final SqliteMedicine? medicine;
  const AddEditMedicineScreen({super.key, this.medicine});

  @override
  State<AddEditMedicineScreen> createState() => _AddEditMedicineScreenState();
}

class _AddEditMedicineScreenState extends State<AddEditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name, _category, _description;
  late double _price;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _name = widget.medicine?.medicineName ?? '';
    _category = widget.medicine?.category ?? '';
    _price = widget.medicine?.price ?? 0.0;
    _quantity = widget.medicine?.quantity ?? 0;
    _description = widget.medicine?.description ?? '';
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final provider = context.read<MedicineProvider>();
    final med = SqliteMedicine(
      id: widget.medicine?.id,
      medicineName: _name,
      category: _category,
      price: _price,
      quantity: _quantity,
      description: _description,
      createdAt: widget.medicine?.createdAt ?? DateTime.now().toIso8601String(),
    );

    if (widget.medicine == null) {
      provider.addMedicine(med);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Medicine added!')));
    } else {
      provider.updateMedicine(med);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Medicine updated!')));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medicine == null ? 'Add New Medicine' : 'Edit Medicine',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Medicine Name'),
              validator: (v) => v!.isEmpty ? 'Enter a name' : null,
              onSaved: (v) => _name = v!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              validator: (v) => v!.isEmpty ? 'Enter a category' : null,
              onSaved: (v) => _category = v!,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _price == 0 ? '' : _price.toString(),
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                    validator: (v) => double.tryParse(v!) == null
                        ? 'Enter valid price'
                        : null,
                    onSaved: (v) => _price = double.parse(v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _quantity == 0 ? '' : _quantity.toString(),
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (v) => int.tryParse(v!) == null
                        ? 'Enter valid quantity'
                        : null,
                    onSaved: (v) => _quantity = int.parse(v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              validator: (v) => v!.isEmpty ? 'Enter description' : null,
              onSaved: (v) => _description = v!,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveForm,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
