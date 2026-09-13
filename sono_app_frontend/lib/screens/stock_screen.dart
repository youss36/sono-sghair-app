import 'package:flutter/material.dart';

import '../models/equipment.dart';
import '../services/equipment_api_service.dart';
import '../theme/app_theme.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key, this.isAdmin = true});

  final bool isAdmin;

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final List<Equipment> _equipments = [];
  final _equipmentApi = EquipmentApiService();
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadEquipments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Equipment> get _filteredEquipments {
    final query = _query.trim().toLowerCase();
    final list = query.isEmpty
        ? List<Equipment>.from(_equipments)
        : _equipments
            .where((e) => e.nomMateriel.toLowerCase().contains(query))
            .toList();
    list.sort((a, b) => a.nomMateriel.compareTo(b.nomMateriel));
    return list;
  }

  int get _totalQuantity =>
      _equipments.fold(0, (sum, e) => sum + e.quantiteTotale);

  Future<void> _loadEquipments() async {
    try {
      final equipments = await _equipmentApi.fetchEquipments();
      if (!mounted) return;
      setState(() {
        _equipments
          ..clear()
          ..addAll(equipments);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Impossible de charger le stock. Réessayez.');
    }
  }

  Future<void> _openEquipmentForm({Equipment? equipment}) async {
    final result = await showDialog<Equipment>(
      context: context,
      builder: (_) => _EquipmentDialog(equipment: equipment),
    );
    if (result == null) return;

    try {
      if (equipment == null) {
        final saved = await _equipmentApi.createEquipment(result);
        setState(() => _equipments.add(saved));
      } else {
        final saved = await _equipmentApi.updateEquipment(result);
        setState(() {
          final index = _equipments.indexWhere((e) => e.id == equipment.id);
          if (index != -1) _equipments[index] = saved;
        });
      }
    } catch (error) {
      _showError('Enregistrement impossible. Réessayez.');
    }
  }

  Future<void> _deleteEquipment(Equipment equipment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Supprimer ?',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Supprimer "${equipment.nomMateriel}" du stock ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _equipmentApi.deleteEquipment(equipment.id);
      setState(() => _equipments.removeWhere((e) => e.id == equipment.id));
    } catch (error) {
      _showError('Suppression impossible. Réessayez.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEquipments;

    return Scaffold(
      appBar: AppBar(title: const Text('Matériel / Stock')),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _StockSummary(
                            itemCount: _equipments.length,
                            totalQuantity: _totalQuantity,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'Rechercher un matériel',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                            onChanged: (value) =>
                                setState(() => _query = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucun matériel. Appuyez sur + pour ajouter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final equipment = filtered[index];
                          return _EquipmentCard(
                            equipment: equipment,
                            isAdmin: widget.isAdmin,
                            onEdit: () =>
                                _openEquipmentForm(equipment: equipment),
                            onDelete: () => _deleteEquipment(equipment),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              tooltip: 'Ajouter un matériel',
              onPressed: _openEquipmentForm,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}

class _StockSummary extends StatelessWidget {
  const _StockSummary({required this.itemCount, required this.totalQuantity});

  final int itemCount;
  final int totalQuantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SummaryValue(label: 'Articles', value: '$itemCount'),
          const SizedBox(
            height: 36,
            child: VerticalDivider(color: AppColors.border),
          ),
          _SummaryValue(label: 'Quantité totale', value: '$totalQuantity'),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({
    required this.equipment,
    required this.onEdit,
    required this.onDelete,
    this.isAdmin = true,
  });

  final Equipment equipment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.35),
                ),
              ),
              child: Center(
                child: Text(
                  '${equipment.quantiteTotale}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.nomMateriel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    equipment.quantiteTotale == 0
                        ? 'Rupture de stock'
                        : 'En stock : ${equipment.quantiteTotale}',
                    style: TextStyle(
                      color: equipment.quantiteTotale == 0
                          ? Colors.redAccent
                          : AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isAdmin)
              IconButton(
                tooltip: 'Modifier',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: AppColors.gold),
              ),
            if (isAdmin)
              IconButton(
                tooltip: 'Supprimer',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentDialog extends StatefulWidget {
  const _EquipmentDialog({this.equipment});

  final Equipment? equipment;

  @override
  State<_EquipmentDialog> createState() => _EquipmentDialogState();
}

class _EquipmentDialogState extends State<_EquipmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.equipment?.nomMateriel ?? '';
    _quantityController.text = '${widget.equipment?.quantiteTotale ?? 0}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Equipment(
        id: widget.equipment?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        nomMateriel: _nameController.text.trim(),
        quantiteTotale: int.tryParse(_quantityController.text.trim()) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.equipment == null ? 'Ajouter un matériel' : 'Modifier le matériel',
        style: const TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nom du matériel',
                hintText: 'Ex : Château, Sub, Retour...',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Veuillez saisir le nom.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantité totale',
                prefixIcon: Icon(Icons.numbers_rounded),
              ),
              validator: (value) {
                final parsed = int.tryParse((value ?? '').trim());
                if (parsed == null || parsed < 0) {
                  return 'Veuillez saisir un nombre valide.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Annuler',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: Icon(
            widget.equipment == null
                ? Icons.add_rounded
                : Icons.check_rounded,
          ),
          label:
              Text(widget.equipment == null ? 'Ajouter' : 'Enregistrer'),
        ),
      ],
    );
  }
}
