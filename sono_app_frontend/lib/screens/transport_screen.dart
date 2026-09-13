import 'package:flutter/material.dart';

import '../models/transport_vehicle.dart';
import '../services/transport_api_service.dart';
import '../theme/app_theme.dart';

class TransportScreen extends StatefulWidget {
  const TransportScreen({super.key, this.isAdmin = true});

  final bool isAdmin;

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  final List<TransportVehicle> _vehicles = [];
  final _vehicleApi = TransportApiService();
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransportVehicle> get _filteredVehicles {
    final query = _query.trim().toLowerCase();
    final list = query.isEmpty
        ? List<TransportVehicle>.from(_vehicles)
        : _vehicles
            .where((v) =>
                v.modele.toLowerCase().contains(query) ||
                v.matricule.toLowerCase().contains(query))
            .toList();
    list.sort((a, b) => a.modele.compareTo(b.modele));
    return list;
  }

  Future<void> _loadVehicles() async {
    try {
      final vehicles = await _vehicleApi.fetchVehicles();
      if (!mounted) return;
      setState(() {
        _vehicles
          ..clear()
          ..addAll(vehicles);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(
          'Impossible de charger le transport. Réessayez.');
    }
  }

  Future<void> _openVehicleForm({TransportVehicle? vehicle}) async {
    final result = await showDialog<TransportVehicle>(
      context: context,
      builder: (_) => _VehicleDialog(vehicle: vehicle),
    );
    if (result == null) return;

    try {
      if (vehicle == null) {
        final saved = await _vehicleApi.createVehicle(result);
        setState(() => _vehicles.add(saved));
      } else {
        final saved = await _vehicleApi.updateVehicle(result);
        setState(() {
          final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
          if (index != -1) _vehicles[index] = saved;
        });
      }
    } catch (error) {
      _showError('Enregistrement impossible. Réessayez.');
    }
  }

  Future<void> _deleteVehicle(TransportVehicle vehicle) async {
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
          'Supprimer "${vehicle.modele}" du transport ?',
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
      await _vehicleApi.deleteVehicle(vehicle.id);
      setState(() => _vehicles.removeWhere((v) => v.id == vehicle.id));
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
    final filtered = _filteredVehicles;

    return Scaffold(
      appBar: AppBar(title: const Text('Transport')),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              )
            : RefreshIndicator(
                color: AppColors.gold,
                onRefresh: _loadVehicles,
                child: CustomScrollView(
                  slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _TransportSummary(count: _vehicles.length),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'Rechercher un véhicule',
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
                          'Aucun véhicule. Appuyez sur + pour ajouter.',
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
                          final vehicle = filtered[index];
                          return _VehicleCard(
                            vehicle: vehicle,
                            isAdmin: widget.isAdmin,
                            onEdit: () =>
                                _openVehicleForm(vehicle: vehicle),
                            onDelete: () => _deleteVehicle(vehicle),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              tooltip: 'Ajouter un véhicule',
              onPressed: _openVehicleForm,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}

class _TransportSummary extends StatelessWidget {
  const _TransportSummary({required this.count});

  final int count;

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
      child: Column(
        children: [
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Véhicules',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
    this.isAdmin = true,
  });

  final TransportVehicle vehicle;
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
              child: const Icon(
                Icons.local_shipping_outlined,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.modele,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicle.matricule,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 13),
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

class _VehicleDialog extends StatefulWidget {
  const _VehicleDialog({this.vehicle});

  final TransportVehicle? vehicle;

  @override
  State<_VehicleDialog> createState() => _VehicleDialogState();
}

class _VehicleDialogState extends State<_VehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _modeleController = TextEditingController();
  final _matriculeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _modeleController.text = widget.vehicle?.modele ?? '';
    _matriculeController.text = widget.vehicle?.matricule ?? '';
  }

  @override
  void dispose() {
    _modeleController.dispose();
    _matriculeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      TransportVehicle(
        id: widget.vehicle?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        modele: _modeleController.text.trim(),
        matricule: _matriculeController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.vehicle == null ? 'Ajouter un véhicule' : 'Modifier le véhicule',
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
              controller: _modeleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Modèle',
                hintText: 'Ex : Citroen Jumper, Fiat Doblo...',
                prefixIcon: Icon(Icons.local_shipping_outlined),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Veuillez saisir le modèle.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _matriculeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Matricule',
                hintText: 'Ex : 1234 TU 567',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Veuillez saisir le matricule.';
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
            widget.vehicle == null
                ? Icons.add_rounded
                : Icons.check_rounded,
          ),
          label: Text(widget.vehicle == null ? 'Ajouter' : 'Enregistrer'),
        ),
      ],
    );
  }
}
