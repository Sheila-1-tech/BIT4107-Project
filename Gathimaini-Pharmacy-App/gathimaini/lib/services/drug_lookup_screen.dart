import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

import '../models/medicine.dart';
import 'pharmacy_service.dart';

class DrugLookupScreen extends StatefulWidget {
  const DrugLookupScreen({super.key});

  @override
  State<DrugLookupScreen> createState() => _DrugLookupScreenState();
}

class _DrugLookupScreenState extends State<DrugLookupScreen> {
  late Future<List<dynamic>> _medicinesFuture;
  Future<List<dynamic>>? _medicinesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final StreamSubscription<List<Medicine>> _medSub;
  List<Medicine> _localMedicines = [];

  @override
  void initState() {
    super.initState();
    _medicinesFuture = fetchMedicines();
    _localMedicines = PharmacyService.instance.allMedicines;
    _medSub = PharmacyService.instance.medicinesStream.listen((list) {
      if (mounted) setState(() => _localMedicines = list);
    });
  }

  @override
  void dispose() {
    _medSub.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Asynchronously fetches a list of medicines from the FDA REST API
  Future<List<dynamic>> fetchMedicines([String query = '']) async {
    String urlStr =
        'https://api.fda.gov/drug/label.json?search=openfda.product_type:"HUMAN PRESCRIPTION DRUG"';

    if (query.isNotEmpty) {
      urlStr +=
          '+AND+(openfda.brand_name:"$query"+OR+openfda.generic_name:"$query")';
    }

    urlStr += '&limit=15';

    final url = Uri.parse(urlStr);

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['results'] as List<dynamic>;
    } else if (response.statusCode == 404) {
      return []; // FDA returns 404 when search yields 0 matches
    } else {
      throw Exception('Failed to load medicines from the API');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Online Drug Lookup'),
        title: const Text('Medicines & FDA Lookup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.storage_rounded),
            tooltip: 'View Local DB',
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _medicinesFuture = null;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _medicinesFuture = fetchMedicines();
                if (_searchQuery.isNotEmpty) {
                  _medicinesFuture = fetchMedicines(_searchQuery);
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: _searchQuery.isEmpty || _medicinesFuture == null
          ? FloatingActionButton(
              onPressed: () => _showAddEditMedicineDialog(context),
              backgroundColor: const Color(0xFF1B8F4A),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  if (value.isEmpty) {
                    _medicinesFuture = null;
                  }
                });
              },
              onSubmitted: (value) {
                setState(() {
                  _searchQuery = value.trim();
                  _medicinesFuture = fetchMedicines(_searchQuery);
                });
              },
              decoration: InputDecoration(
                hintText: 'Search brand or manufacturer...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1B8F4A)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _medicinesFuture = fetchMedicines('');
                            _medicinesFuture = null;
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _medicinesFuture,
              builder: (context, snapshot) {
            child: _searchQuery.isEmpty || _medicinesFuture == null
                ? _buildLocalDbList()
                : FutureBuilder<List<dynamic>>(
                    future: _medicinesFuture,
                    builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B8F4A)),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.redAccent,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No medicines found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                final medicines = snapshot.data!;
                final query = _searchQuery.toLowerCase();

                final filteredMedicines = medicines.where((medicine) {
                  final openfda = medicine['openfda'] ?? {};
                  final brandName =
                      ((openfda['brand_name'] as List<dynamic>?)?.first ??
                              'Unknown Brand')
                          .toString()
                          .toLowerCase();
                  final manufacturer =
                      ((openfda['manufacturer_name'] as List<dynamic>?)
                                  ?.first ??
                              'Unknown Manufacturer')
                          .toString()
                          .toLowerCase();
                  return brandName.contains(query) ||
                      manufacturer.contains(query);
                }).toList();

                if (filteredMedicines.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching medicines found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredMedicines.length,
                  itemBuilder: (context, index) {
                    final medicine = filteredMedicines[index];
                    final openfda = medicine['openfda'] ?? {};

                    // Safely extract data from the FDA API response
                    final brandName =
                        (openfda['brand_name'] as List<dynamic>?)?.first ??
                        'Unknown Brand';
                    final manufacturer =
                        (openfda['manufacturer_name'] as List<dynamic>?)
                            ?.first ??
                        'Unknown Manufacturer';
                    final purpose =
                        (medicine['purpose'] as List<dynamic>?)?.first ??
                        (medicine['indications_and_usage'] as List<dynamic>?)
                            ?.first ??
                        (medicine['description'] as List<dynamic>?)?.first ??
                        'Purpose not provided by manufacturer.';

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF7EF),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.medication_liquid_rounded,
                                    color: Color(0xFF1B8F4A),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        brandName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF123A28),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        manufacturer,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Purpose & Indications',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF123A28),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              purpose,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (_localMedicines.any((m) => m.name.toLowerCase() == brandName.toLowerCase()))
                                  const Chip(
                                    label: Text('In Inventory'),
                                    backgroundColor: Color(0xFFEAF7EF),
                                    labelStyle: TextStyle(
                                      color: Color(0xFF1B8F4A),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    side: BorderSide.none,
                                  )
                                else
                                  FilledButton.icon(
                                    onPressed: () async {
                                      final newMed = Medicine(
                                        id: 'fda_${DateTime.now().millisecondsSinceEpoch}',
                                        name: brandName,
                                        category: 'FDA Import',
                                        price: 0.0, // Requires manual pricing update later
                                        stockQuantity: 0,
                                        description: purpose,
                                        rating: 0.0,
                                      );
                                      try {
                                        await PharmacyService.instance.addMedicine(newMed);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('$brandName added to inventory.'),
                                            action: SnackBarAction(
                                              label: 'View',
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {
                                                  _searchQuery = '';
                                                  _medicinesFuture = null;
                                                });
                                              },
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to add: $e')),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.add_to_photos_rounded),
                                    label: const Text('Add to Inventory'),
                                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1B8F4A)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalDbList() {
    if (_localMedicines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storage_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Your local inventory is empty.',
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
      itemCount: _localMedicines.length,
      itemBuilder: (context, index) {
        final medicine = _localMedicines[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEAF7EF),
              child: Icon(Icons.medication, color: Color(0xFF1B8F4A)),
            ),
            title: Text(
              medicine.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Ksh ${medicine.price.toStringAsFixed(0)} • ${medicine.category ?? 'General'}\nStock: ${medicine.stockQuantity}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => _showAddEditMedicineDialog(context, medicine),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _deleteMedicine(medicine.id),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                  id: existing?.id ?? 'med_${DateTime.now().millisecondsSinceEpoch}',
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
    } catch (e) {
      debugPrint('Error deleting: $e');
    }
  }
}
