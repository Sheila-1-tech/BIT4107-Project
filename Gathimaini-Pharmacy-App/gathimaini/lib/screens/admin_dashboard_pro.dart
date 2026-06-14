import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../models/order.dart';
import '../models/prescription.dart';
import '../services/auth_service.dart';
import '../services/pharmacy_service.dart';
import '../services/database_helper.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  late final StreamSubscription<List<Medicine>> _medSub;
  List<Medicine> _medicines = <Medicine>[];

  late final StreamSubscription<List<Order>> _orderSub;
  List<Order> _pendingOrders = <Order>[];

  late final StreamSubscription<List<Prescription>> _rxSub;
  List<Prescription> _pendingPrescriptions = <Prescription>[];

  final List<_LowStockItem> _lowStockItems = const [
    _LowStockItem(name: 'Insulin pen', remaining: 6),
    _LowStockItem(name: 'Allergy tablets', remaining: 8),
    _LowStockItem(name: 'BP strips', remaining: 5),
  ];

  @override
  void initState() {
    super.initState();
    _medicines = PharmacyService.instance.allMedicines;
    _medSub = PharmacyService.instance.medicinesStream.listen((list) {
      if (!mounted) {
        return;
      }
      setState(() => _medicines = list);
    });

    _pendingOrders = PharmacyService.instance.pendingOrders;
    _orderSub = PharmacyService.instance.ordersStream.listen((list) {
      if (!mounted) return;
      setState(
        () => _pendingOrders = list
            .where(
              (o) =>
                  o.status == OrderStatus.placed ||
                  o.status == OrderStatus.processing,
            )
            .toList(),
      );
    });

    _pendingPrescriptions = PharmacyService.instance.pendingPrescriptions;
    _rxSub = PharmacyService.instance.prescriptionsStream.listen((list) {
      if (!mounted) return;
      setState(
        () => _pendingPrescriptions = list
            .where((p) => p.status == 'pending')
            .toList(),
      );
    });
  }

  @override
  void dispose() {
    _medSub.cancel();
    _orderSub.cancel();
    _rxSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pharmacy Admin',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 2),
            Text(
              'Inventory, orders, and reports in one place',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showMessage('No new notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFC94A4A)),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildCurrentTab(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE3F4EA),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_rounded),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Reports',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _openMedicineEditor(context),
              backgroundColor: const Color(0xFF1B8F4A),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add medicine',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            )
          : null,
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 1:
        return _InventoryTab(
          medicines: _medicines,
          searchQuery: _searchQuery,
          onSearchChanged: (value) => setState(() => _searchQuery = value),
          onAdd: () => _openMedicineEditor(context),
          onEdit: (medicine) =>
              _openMedicineEditor(context, existing: medicine),
          onDelete: (id) => _confirmDelete(context, id),
        );
      case 2:
        return _ReportsTab(
          medicines: _medicines,
          lowStockItems: _lowStockItems,
          onActionTap: _showMessage,
        );
      case 0:
      default:
        return _OverviewTab(
          medicines: _medicines,
          pendingOrders: _pendingOrders,
          pendingPrescriptions: _pendingPrescriptions,
          lowStockItems: _lowStockItems,
          onGoToInventory: () => setState(() => _selectedIndex = 1),
          onGoToReports: () => setState(() => _selectedIndex = 2),
          onActionTap: _showMessage,
          onOpenRequests: _openRequestsPanel,
          onReviewOrder: _reviewOrder,
          onReviewPrescription: _reviewPrescription,
        );
    }
  }

  Future<void> _openMedicineEditor(
    BuildContext context, {
    Medicine? existing,
  }) async {
    final result = await showModalBottomSheet<_MedicineFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _MedicineEditorSheet(existing: existing),
    );

    if (!mounted || result == null) {
      return;
    }

    try {
      if (result.isNew) {
        await PharmacyService.instance.addMedicine(result.medicine);
        _showMessage('Medicine added');
      } else {
        await PharmacyService.instance.updateMedicine(result.medicine);
        _showMessage('Medicine updated');
      }
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete medicine'),
        content: const Text(
          'This will remove the medicine from inventory. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await PharmacyService.instance.deleteMedicine(id);
        _showMessage('Medicine deleted');
      } catch (e) {
        _showMessage('Delete failed: $e');
      }
    }
  }

  void _showMessage(String label) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC94A4A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && context.mounted) {
      await AuthService.instance.logout();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _reviewPrescription(Prescription rx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Review Prescription',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Text(
              'Customer: ${rx.customerName}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Notes: ${rx.notes.isEmpty ? "None provided" : rx.notes}',
              style: TextStyle(color: Colors.grey.shade800),
            ),
            const SizedBox(height: 24),
            if (rx.fileUrl != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: rx.isDocument
                      ? const Icon(
                          Icons.picture_as_pdf,
                          size: 80,
                          color: Color(0xFF1B8F4A),
                        )
                      : (kIsWeb ||
                                rx.fileUrl!.startsWith('http') ||
                                rx.fileUrl!.startsWith('blob:')
                            ? Image.network(
                                rx.fileUrl!,
                                height: 250,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(rx.fileUrl!),
                                height: 250,
                                fit: BoxFit.cover,
                              )),
                ),
              ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      PharmacyService.instance.updatePrescriptionStatus(
                        rx.id,
                        'rejected',
                      );
                      Navigator.pop(ctx);
                      _showMessage('${rx.id} rejected');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      PharmacyService.instance.updatePrescriptionStatus(
                        rx.id,
                        'approved',
                      );
                      Navigator.pop(ctx);
                      _showMessage('${rx.id} approved for processing');
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF1B8F4A),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _reviewOrder(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Review Order',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Text(
              'Order: ORD-${order.id.substring(order.id.length > 5 ? order.id.length - 5 : 0)}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Customer: ${order.userId}',
              style: TextStyle(color: Colors.grey.shade800),
            ),
            const SizedBox(height: 8),
            Text(
              'Items: ${order.items.map((item) => item.name).join(', ')}',
              style: TextStyle(color: Colors.grey.shade800),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: Ksh ${order.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      PharmacyService.instance.updateOrderStatus(
                        order.id,
                        OrderStatus.cancelled,
                      );
                      Navigator.pop(ctx);
                      _showMessage('${order.id} cancelled');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      PharmacyService.instance.updateOrderStatus(
                        order.id,
                        OrderStatus.processing,
                      );
                      Navigator.pop(ctx);
                      _showMessage('${order.id} moved to processing');
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF1B8F4A),
                    ),
                    child: const Text('Process'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openRequestsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4DED8),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Incoming requests',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Orders and prescriptions waiting for admin review.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Orders requested',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                if (_pendingOrders.isEmpty)
                  const Text('No active orders yet.')
                else
                  ..._pendingOrders.map(
                    (order) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(
                          'Order ${order.id.substring(order.id.length > 5 ? order.id.length - 5 : 0)}',
                        ),
                        subtitle: Text(
                          '${order.items.length} item(s) • Ksh ${order.total.toStringAsFixed(2)}',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _reviewOrder(order);
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                const Text(
                  'Prescriptions',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                if (_pendingPrescriptions.isEmpty)
                  const Text('No pending prescriptions yet.')
                else
                  ..._pendingPrescriptions.map(
                    (rx) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text('Prescription ${rx.id}'),
                        subtitle: Text(rx.customerName),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _reviewPrescription(rx);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.medicines,
    required this.pendingOrders,
    required this.pendingPrescriptions,
    required this.lowStockItems,
    required this.onGoToInventory,
    required this.onGoToReports,
    required this.onActionTap,
    required this.onOpenRequests,
    required this.onReviewOrder,
    required this.onReviewPrescription,
  });

  final List<Medicine> medicines;
  final List<Order> pendingOrders;
  final List<Prescription> pendingPrescriptions;
  final List<_LowStockItem> lowStockItems;
  final VoidCallback onGoToInventory;
  final VoidCallback onGoToReports;
  final ValueChanged<String> onActionTap;
  final VoidCallback onOpenRequests;
  final ValueChanged<Order> onReviewOrder;
  final ValueChanged<Prescription> onReviewPrescription;

  @override
  Widget build(BuildContext context) {
    final categories = medicines.map((m) => m.category ?? 'General').toSet();

    final cards = [
      _DashboardCardData(
        title: 'Medicines',
        value: medicines.length.toString(),
        subtitle: 'Active products in catalog',
        icon: Icons.medication_outlined,
        color: const Color(0xFF1B8F4A),
      ),
      _DashboardCardData(
        title: 'Categories',
        value: categories.length.toString(),
        subtitle: 'Product groupings',
        icon: Icons.category_outlined,
        color: const Color(0xFF2E7BFF),
      ),
      _DashboardCardData(
        title: 'Low stock',
        value: lowStockItems.length.toString(),
        subtitle: 'Needs replenishment',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFFC7781A),
      ),
      _DashboardCardData(
        title: 'Orders',
        value: pendingOrders.length.toString(),
        subtitle: 'Requested / processing',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFFDA6A43),
      ),
      _DashboardCardData(
        title: 'Revenue',
        value: 'Ksh 184k',
        subtitle: 'Sales today',
        icon: Icons.attach_money_rounded,
        color: const Color(0xFF7A5BC4),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
      children: [
        _HeroBanner(
          title: 'Operational control for pharmacy staff',
          subtitle:
              'Monitor stock, review prescriptions, and keep the catalog clean from a dashboard that feels business-ready.',
          primaryActionLabel: 'Open inventory',
          secondaryActionLabel: 'View reports',
          onPrimaryAction: onGoToInventory,
          onSecondaryAction: onGoToReports,
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Overview'),
        const SizedBox(height: 12),
        _DashboardGrid(cards: cards),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Quick actions'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final children = [
              _QuickActionCard(
                icon: Icons.receipt_long_rounded,
                title: 'Orders',
                description: 'Review pending sales',
                color: const Color(0xFFC7781A),
                onTap: onOpenRequests,
              ),
              _QuickActionCard(
                icon: Icons.inventory_2_outlined,
                title: 'Inventory',
                description: 'Manage medicines',
                color: const Color(0xFF2E7BFF),
                onTap: onGoToInventory,
              ),
              _QuickActionCard(
                icon: Icons.analytics_outlined,
                title: 'Reports',
                description: 'Check performance',
                color: const Color(0xFF7A5BC4),
                onTap: onGoToReports,
              ),
              _QuickActionCard(
                icon: Icons.travel_explore_rounded,
                title: 'Lookup & SQLite',
                description: 'API & Local DB',
                color: const Color(0xFF1B8F4A),
                onTap: () => Navigator.pushNamed(context, '/drug-lookup'),
              ),
            ];

            if (isWide) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: children[0]),
                      const SizedBox(width: 12),
                      Expanded(child: children[1]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: children[2]),
                      const SizedBox(width: 12),
                      Expanded(child: children[3]),
                    ],
                  ),
                ],
              );
            }

            return Column(
              children: [
                children[0],
                const SizedBox(height: 12),
                children[1],
                const SizedBox(height: 12),
                children[2],
                const SizedBox(height: 12),
                children[3],
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Orders requested'),
        const SizedBox(height: 12),
        if (pendingOrders.isEmpty)
          _EmptyState(
            title: 'No active orders',
            subtitle: 'New customer checkouts will appear here.',
            actionLabel: 'Refresh',
            onAction: () {},
          )
        else
          ...pendingOrders.map(
            (order) => _ActionTile(
              title:
                  'Order ${order.id.substring(order.id.length > 5 ? order.id.length - 5 : 0)}',
              subtitle:
                  '${order.items.map((item) => item.name).join(', ')} • Ksh ${order.total.toStringAsFixed(2)}',
              icon: Icons.receipt_long_rounded,
              iconColor: const Color(0xFFDA6A43),
              backgroundColor: const Color(0xFFFFF5EE),
              buttonLabel: 'Review',
              buttonColor: const Color(0xFFDA6A43),
              onTap: () => onReviewOrder(order),
            ),
          ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Action required'),
        const SizedBox(height: 12),
        ...pendingPrescriptions.map(
          (item) => _ActionTile(
            title: 'Prescription ${item.id}',
            subtitle: '${item.customerName} • ${item.date}',
            icon: Icons.document_scanner_outlined,
            iconColor: const Color(0xFF1B8F4A),
            backgroundColor: const Color(0xFFF3FAF4),
            buttonLabel: 'Review',
            buttonColor: const Color(0xFF1B8F4A),
            onTap: () => onReviewPrescription(item),
          ),
        ),
        const SizedBox(height: 8),
        ...lowStockItems.map((item) => _LowStockCard(item: item)),
      ],
    );
  }
}

class _InventoryTab extends StatelessWidget {
  const _InventoryTab({
    required this.medicines,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Medicine> medicines;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAdd;
  final ValueChanged<Medicine> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.trim().toLowerCase();
    final filteredMedicines = medicines.where((medicine) {
      if (query.isEmpty) {
        return true;
      }
      return medicine.name.toLowerCase().contains(query) ||
          (medicine.category ?? '').toLowerCase().contains(query) ||
          medicine.description.toLowerCase().contains(query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
      children: [
        const _SectionTitle(
          title: 'Inventory',
          subtitle: 'Search, edit, and manage the live medicine catalog.',
        ),
        const SizedBox(height: 12),
        _SearchPanel(
          searchQuery: searchQuery,
          onSearchChanged: onSearchChanged,
          onAdd: onAdd,
        ),
        const SizedBox(height: 14),
        _InventorySummaryBar(
          total: medicines.length,
          visible: filteredMedicines.length,
          categories: medicines
              .map((m) => m.category ?? 'General')
              .toSet()
              .length,
        ),
        const SizedBox(height: 14),
        if (filteredMedicines.isEmpty)
          _EmptyState(
            title: 'No medicines found',
            subtitle: 'Try another search term or add a new product.',
            actionLabel: 'Add medicine',
            onAction: onAdd,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 1100
                  ? 4
                  : width >= 700
                  ? 3
                  : 2;
              return GridView.builder(
                itemCount: filteredMedicines.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.65,
                ),
                itemBuilder: (context, index) {
                  final medicine = filteredMedicines[index];
                  return _MedicineCard(
                    medicine: medicine,
                    onEdit: () => onEdit(medicine),
                    onDelete: () => onDelete(medicine.id),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class _ReportsTab extends StatefulWidget {
  const _ReportsTab({
    required this.medicines,
    required this.lowStockItems,
    required this.onActionTap,
  });

  final List<Medicine> medicines;
  final List<_LowStockItem> lowStockItems;
  final ValueChanged<String> onActionTap;

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  bool _isGenerating = false;

  Future<void> _generateSqliteReport() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Fetch real data from the local database
      final localMedicines = await DatabaseHelper.instance.getAllMedicines();

      int totalItems = localMedicines.length;
      double totalValue = localMedicines.fold(
        0.0,
        (sum, m) => sum + (m.price * (m.stockQuantity ?? 0)),
      );
      int lowStock = localMedicines
          .where((m) => (m.stockQuantity ?? 0) < 10)
          .length;

      if (!mounted) return;

      // Display the report instantly in a nice dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Local SQLite Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Local Medicines: $totalItems',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Low Stock Items (<10): $lowStock',
                style: const TextStyle(fontSize: 16, color: Colors.redAccent),
              ),
              const SizedBox(height: 12),
              Text(
                'Total Inventory Value:\nKsh ${totalValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B8F4A),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryCounts = <String, int>{};
    for (final medicine in widget.medicines) {
      final category = medicine.category ?? 'General';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    final topCategory = categoryCounts.isEmpty
        ? 'N/A'
        : categoryCounts.entries
              .reduce((a, b) => a.value >= b.value ? a : b)
              .key;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
      children: [
        const _SectionTitle(
          title: 'Reports',
          subtitle:
              'Summaries that feel closer to a real operations dashboard.',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatChip(
                label: 'Products',
                value: widget.medicines.length.toString(),
                icon: Icons.medication_outlined,
                color: const Color(0xFF1B8F4A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatChip(
                label: 'Low stock',
                value: widget.lowStockItems.length.toString(),
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFC7781A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _AnalyticsCard(
          title: 'Sales mix',
          subtitle: 'Breakdown by category',
          child: _SimpleBarChart(entries: categoryCounts),
        ),
        const SizedBox(height: 14),
        _AnalyticsCard(
          title: 'Inventory insights',
          subtitle: 'Operational notes for the pharmacy team',
          child: Column(
            children: [
              _InsightRow(
                label: 'Top category',
                value: topCategory,
                icon: Icons.local_pharmacy_outlined,
              ),
              const SizedBox(height: 10),
              _InsightRow(
                label: 'Medicines with images',
                value: widget.medicines
                    .where((m) => (m.imageUrl ?? '').isNotEmpty)
                    .length
                    .toString(),
                icon: Icons.image_outlined,
              ),
              const SizedBox(height: 10),
              _InsightRow(
                label: 'Needs replenishment',
                value: widget.lowStockItems.length.toString(),
                icon: Icons.inventory_2_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _AnalyticsCard(
          title: 'Suggested actions',
          subtitle: 'Useful next steps for staff',
          child: Column(
            children: [
              _ActionButton(
                label: _isGenerating
                    ? 'Generating...'
                    : 'Generate SQLite Report',
                icon: _isGenerating
                    ? Icons.hourglass_empty
                    : Icons.analytics_outlined,
                onTap: _isGenerating ? () {} : _generateSqliteReport,
              ),
              const SizedBox(height: 10),
              _ActionButton(
                label: 'Review stock alerts',
                icon: Icons.notification_important_outlined,
                onTap: () => widget.onActionTap('Review stock alerts'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({required this.cards});

  final List<_DashboardCardData> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final crossAxisCount = maxWidth >= 900
            ? 4
            : maxWidth >= 600
            ? 2
            : 1;
        return GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: crossAxisCount == 1 ? 2.5 : 1.12,
          ),
          itemBuilder: (context, index) => _MetricCard(data: cards[index]),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _DashboardCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(data.icon, color: data.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF123A28),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF476255),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.title,
    required this.subtitle,
    required this.primaryActionLabel,
    required this.secondaryActionLabel,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
  });

  final String title;
  final String subtitle;
  final String primaryActionLabel;
  final String secondaryActionLabel;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173F2E), Color(0xFF1B8F4A)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B8F4A).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.local_pharmacy_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton(
                      onPressed: onPrimaryAction,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1B8F4A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(primaryActionLabel),
                    ),
                    OutlinedButton(
                      onPressed: onSecondaryAction,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(secondaryActionLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4ECE8)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF123A28),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE4ECE8)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF7D8A82)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.medicine,
    required this.onEdit,
    required this.onDelete,
  });

  final Medicine medicine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.6,
                    child: _MedicineImage(imageUrl: medicine.imageUrl),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _CategoryChip(label: medicine.category ?? 'General'),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _ActionCircleButton(
                    icon: Icons.edit_rounded,
                    color: const Color(0xFF1B8F4A),
                    onTap: onEdit,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF123A28),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  medicine.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Ksh ${medicine.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B8F4A),
                      ),
                    ),
                    const Spacer(),
                    _ActionCircleButton(
                      icon: Icons.delete_outline_rounded,
                      color: const Color(0xFFD64B4B),
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineImage extends StatelessWidget {
  const _MedicineImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final text = imageUrl?.trim() ?? '';
    if (text.isEmpty) {
      return Container(
        color: const Color(0xFFF3FAF4),
        child: const Center(
          child: Icon(
            Icons.medication_outlined,
            color: Color(0xFF1B8F4A),
            size: 42,
          ),
        ),
      );
    }

    if (text.startsWith('http://') || text.startsWith('https://')) {
      return Image.network(
        text,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          return Container(
            color: const Color(0xFFF3FAF4),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const _BrokenImagePlaceholder(message: 'Image unavailable');
        },
      );
    }

    return const _BrokenImagePlaceholder(
      message: 'Use an http or https image URL',
    );
  }
}

class _MedicineEditorSheet extends StatefulWidget {
  const _MedicineEditorSheet({required this.existing});

  final Medicine? existing;

  @override
  State<_MedicineEditorSheet> createState() => _MedicineEditorSheetState();
}

class _MedicineEditorSheetState extends State<_MedicineEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageController;
  late final List<String> _categoryOptions;
  String? _selectedCategory;
  final bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _idController = TextEditingController(text: existing?.id ?? '');
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _priceController = TextEditingController(
      text: existing == null ? '' : existing.price.toStringAsFixed(0),
    );
    _categoryOptions = [
      'General',
      'Analgesics',
      'Antibiotics',
      'Antifungals',
      'Antivirals',
      'Antimalarials',
      'Antiseptics',
      'Allergy & Antihistamines',
      'Respiratory',
      'Cough & Cold',
      'Gastrointestinal',
      'Acidity & Ulcer',
      'Pain Relief',
      'Fever & Flu',
      'Cardiovascular',
      'Hypertension',
      'Diabetes Care',
      'Endocrine & Hormonal',
      'Vitamins & Supplements',
      'Immunity Support',
      'Dermatology',
      'Skin Care',
      'Eye Care',
      'Ear Care',
      'Oral Care',
      'Dental Care',
      'First Aid',
      'Wound Care',
      'Pain & Inflammation',
      'Children & Pediatrics',
      'Prenatal & Maternity',
      'Women’s Health',
      'Men’s Health',
      'Sexual Wellness',
      'Contraceptives',
      'Neurology',
      'Mental Health',
      'Sleep & Relaxation',
      'Musculoskeletal',
      'Arthritis & Joint Care',
      'Renal & Urinary',
      'Liver Support',
      'Smoking Cessation',
      'Travel Health',
      'Home Care',
      'Medical Devices',
      'Mobility Aids',
      'Inhalers & Nebulizers',
      'Injectables',
      'Prescription Only',
      'Over The Counter',
      'Herbal & Natural',
      'Veterinary',
      'Other',
    ];
    final existingCategory = existing?.category?.trim();
    if (existingCategory != null && existingCategory.isNotEmpty) {
      if (!_categoryOptions.contains(existingCategory)) {
        _categoryOptions.insert(0, existingCategory);
      }
      _selectedCategory = existingCategory;
    } else {
      _selectedCategory = 'General';
    }
    _imageController = TextEditingController(text: existing?.imageUrl ?? '');
    _imageController.addListener(_handleImageChange);
  }

  @override
  void dispose() {
    _imageController.removeListener(_handleImageChange);
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  void _handleImageChange() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickAndUploadImage() async {
    // Workspace does not include image picker / firebase config.
    // Ask user to paste an image URL instead.
    final controller = TextEditingController(text: _imageController.text);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste image URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'https://...'),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (ok == true) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        setState(() => _imageController.text = text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7FAF8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4DED8),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isNew ? 'Add medicine' : 'Edit medicine',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF123A28),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Paste a network image URL and the preview updates immediately. For production use, consider an image picker or cloud upload flow.',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PreviewPanel(imageUrl: _imageController.text),
                    const SizedBox(height: 16),
                    _ModernTextField(
                      controller: _idController,
                      label: 'Medicine ID',
                      hintText: 'Auto-generated if left blank',
                      enabled: isNew,
                      prefixIcon: Icons.tag_rounded,
                    ),
                    const SizedBox(height: 12),
                    _ModernTextField(
                      controller: _nameController,
                      label: 'Medicine name',
                      hintText: 'e.g. Paracetamol 500mg',
                      prefixIcon: Icons.medication_outlined,
                      textInputAction: TextInputAction.next,
                      validator: _requiredValidator('Enter a medicine name'),
                    ),
                    const SizedBox(height: 12),
                    _ModernTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hintText: 'Short product description',
                      prefixIcon: Icons.notes_rounded,
                      maxLines: 3,
                      textInputAction: TextInputAction.newline,
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) {
                          return 'Enter a description';
                        }
                        if (text.length < 8) {
                          return 'Description is too short';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ModernTextField(
                            controller: _priceController,
                            label: 'Price',
                            hintText: '0',
                            prefixIcon: Icons.payments_outlined,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              final parsed = double.tryParse(
                                (value ?? '').trim(),
                              );
                              if (parsed == null || parsed <= 0) {
                                return 'Enter a valid price';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            items: _categoryOptions
                                .map(
                                  (category) => DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(
                                      category,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                            validator: (value) => value == null || value.isEmpty
                                ? 'Select a category'
                                : null,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              prefixIcon: const Icon(
                                Icons.category_outlined,
                                color: Color(0xFF1B8F4A),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE4ECE8),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE4ECE8),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1B8F4A),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ModernTextField(
                            controller: _imageController,
                            label: 'Image URL',
                            hintText: 'Paste a URL or tap upload',
                            prefixIcon: Icons.image_outlined,
                            helperText:
                                'Provide a valid image URL or upload from device.',
                            validator: (value) {
                              final text = (value ?? '').trim();
                              if (text.isEmpty) return null;
                              final uri = Uri.tryParse(text);
                              if (uri == null ||
                                  !(uri.isScheme('http') ||
                                      uri.isScheme('https'))) {
                                return 'Enter a valid http or https URL';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: _isUploadingImage
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : IconButton.filledTonal(
                                  onPressed: _pickAndUploadImage,
                                  icon: const Icon(Icons.upload_file_rounded),
                                  tooltip: 'Upload photo',
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFFD4DED8)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1B8F4A),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              isNew ? 'Add medicine' : 'Save changes',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? Function(String?) _requiredValidator(String message) {
    return (value) => (value ?? '').trim().isEmpty ? message : null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final isNew = widget.existing == null;
    final id = _idController.text.trim().isEmpty
        ? 'med_${DateTime.now().millisecondsSinceEpoch}'
        : _idController.text.trim();
    final category = _selectedCategory?.trim() ?? '';
    final imageUrl = _imageController.text.trim();

    final medicine = Medicine(
      id: id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      rating: widget.existing?.rating ?? 0.0,
      category: category.isEmpty ? null : category,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
    );

    Navigator.of(
      context,
    ).pop(_MedicineFormResult(medicine: medicine, isNew: isNew));
  }
}

class _MedicineFormResult {
  const _MedicineFormResult({required this.medicine, required this.isNew});

  final Medicine medicine;
  final bool isNew;
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onAdd,
  });

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search medicines, categories, or descriptions',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF1B8F4A),
              ),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => onSearchChanged(''),
                      icon: const Icon(Icons.clear_rounded),
                    ),
              filled: true,
              fillColor: const Color(0xFFF7FAF8),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1B8F4A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add medicine'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventorySummaryBar extends StatelessWidget {
  const _InventorySummaryBar({
    required this.total,
    required this.visible,
    required this.categories,
  });

  final int total;
  final int visible;
  final int categories;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TinyInfoCard(label: 'Total', value: total.toString()),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TinyInfoCard(label: 'Visible', value: visible.toString()),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TinyInfoCard(
            label: 'Categories',
            value: categories.toString(),
          ),
        ),
      ],
    );
  }
}

class _TinyInfoCard extends StatelessWidget {
  const _TinyInfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF123A28),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF123A28),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  const _SimpleBarChart({required this.entries});

  final Map<String, int> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyChartState();
    }

    final maxValue = entries.values.reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      children: entries.entries.map((entry) {
        final percent = entry.value / maxValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    entry.value.toString(),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: percent,
                  backgroundColor: const Color(0xFFEAF2EF),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF1B8F4A),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF3FAF4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF1B8F4A), size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF123A28),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: const Color(0xFF1B8F4A),
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.buttonLabel,
    required this.buttonColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String buttonLabel;
  final Color buttonColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4ECE8)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: buttonColor,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.item});

  final _LowStockItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2D8AD)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB37510)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            '${item.remaining} left',
            style: const TextStyle(
              color: Color(0xFF9A6206),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionCircleButton extends StatelessWidget {
  const _ActionCircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      shape: const CircleBorder(),
      elevation: 1.5,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live image preview',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF123A28),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 1.8,
              child: _MedicineImage(imageUrl: imageUrl),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF1B8F4A)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE4ECE8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE4ECE8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF1B8F4A), width: 1.5),
        ),
      ),
    );
  }
}

class _BrokenImagePlaceholder extends StatelessWidget {
  const _BrokenImagePlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3FAF4),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              color: Color(0xFFCF6A6A),
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4ECE8)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 42,
            color: Color(0xFF1B8F4A),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1B8F4A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _EmptyChartState extends StatelessWidget {
  const _EmptyChartState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'No data available yet.',
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF123A28),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _DashboardCardData {
  const _DashboardCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _LowStockItem {
  const _LowStockItem({required this.name, required this.remaining});

  final String name;
  final int remaining;
}
