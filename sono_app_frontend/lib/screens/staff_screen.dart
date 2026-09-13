import 'package:flutter/material.dart';

import '../models/staff_member.dart';
import '../services/staff_api_service.dart';
import '../theme/app_theme.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key, this.isAdmin = true});

  final bool isAdmin;

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final List<StaffMember> _staff = [];
  final _staffApi = StaffApiService();
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StaffMember> get _filteredStaff {
    final query = _query.trim().toLowerCase();
    final list = query.isEmpty
        ? List<StaffMember>.from(_staff)
        : _staff
            .where((m) =>
                m.nomPrenom.toLowerCase().contains(query) ||
                m.role.toLowerCase().contains(query))
            .toList();
    list.sort((a, b) => a.nomPrenom.compareTo(b.nomPrenom));
    return list;
  }

  Future<void> _loadStaff() async {
    try {
      final staff = await _staffApi.fetchStaff();
      if (!mounted) return;
      setState(() {
        _staff
          ..clear()
          ..addAll(staff);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(
          'Impossible de charger le personnel. Lancez le serveur FastAPI (redémarrez-le pour les nouveaux endpoints).');
    }
  }

  Future<void> _openAddForm() async {
    final result = await showDialog<({StaffMember member, String password})>(
      context: context,
      builder: (_) => const _StaffDialog(),
    );
    if (result == null) return;

    try {
      final saved = await _staffApi.createMember(result.member,
          password: result.password);
      setState(() => _staff.add(saved));
    } catch (error) {
      _showError('Ajout impossible. Vérifiez le serveur FastAPI.');
    }
  }

  Future<void> _deleteMember(StaffMember member) async {
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
          'Supprimer "${member.nomPrenom}" du personnel ?',
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
      await _staffApi.deleteMember(member.id);
      setState(() => _staff.removeWhere((m) => m.id == member.id));
    } catch (error) {
      _showError('Suppression impossible. Vérifiez le serveur FastAPI.');
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
    final filtered = _filteredStaff;

    return Scaffold(
      appBar: AppBar(title: const Text('Personnel / Staff')),
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
                          _StaffSummary(count: _staff.length),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'Rechercher un travailleur',
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
                          'Aucun travailleur. Appuyez sur + pour ajouter.',
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
                          final member = filtered[index];
                          return _StaffCard(
                            member: member,
                            isAdmin: widget.isAdmin,
                            onDelete: () => _deleteMember(member),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              tooltip: 'Ajouter un travailleur',
              onPressed: _openAddForm,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}

class _StaffSummary extends StatelessWidget {
  const _StaffSummary({required this.count});

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
            'Travailleurs',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard(
      {required this.member, required this.onDelete, this.isAdmin = true});

  final StaffMember member;
  final VoidCallback onDelete;
  final bool isAdmin;

  IconData get _roleIcon {
    switch (member.role) {
      case 'Admin':
        return Icons.admin_panel_settings_outlined;
      case 'Technicien':
        return Icons.engineering_outlined;
      default:
        return Icons.person_outline_rounded;
    }
  }

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
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(_roleIcon, color: AppColors.gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.nomPrenom,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${member.role} • ${member.email}',
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
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

class _StaffDialog extends StatefulWidget {
  const _StaffDialog();

  @override
  State<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends State<_StaffDialog> {
  static const _roles = ['Aideur', 'Technicien', 'Admin'];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: 'sono1234');
  String _selectedRole = _roles.first;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      (
        member: StaffMember(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          nomPrenom: _nameController.text.trim(),
          email: _emailController.text.trim(),
          role: _selectedRole,
        ),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Ajouter un travailleur',
        style: TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nom et prénom',
                  prefixIcon: Icon(Icons.person_outline_rounded),
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
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (value) {
                  final email = (value ?? '').trim();
                  if (email.isEmpty) return 'Veuillez saisir l\'email.';
                  if (!email.contains('@')) return 'Email invalide.';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(labelText: 'Rôle'),
                items: _roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedRole = value);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').isEmpty) {
                    return 'Veuillez saisir un mot de passe.';
                  }
                  return null;
                },
              ),
            ],
          ),
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
          icon: const Icon(Icons.add_rounded),
          label: const Text('Ajouter'),
        ),
      ],
    );
  }
}
