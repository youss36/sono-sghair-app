import 'package:flutter/material.dart';

import '../models/staff_member.dart';
import '../theme/app_theme.dart';
import 'events_screen.dart';
import 'login_screen.dart';
import 'staff_screen.dart';
import 'stock_screen.dart';
import 'transport_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, required this.user});

  final StaffMember user;

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Déconnexion ?',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.isAdmin;
    final quickActions = [
      _QuickAction(
        icon: Icons.inventory_2_outlined,
        title: 'Matériel / Stock',
        subtitle: 'Inventaire et disponibilité',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => StockScreen(isAdmin: isAdmin)),
        ),
      ),
      _QuickAction(
        icon: Icons.groups_2_outlined,
        title: 'Personnel / Staff',
        subtitle: 'Techniciens et aideurs',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => StaffScreen(isAdmin: isAdmin)),
        ),
      ),
      _QuickAction(
        icon: Icons.event_available_outlined,
        title: 'Événements',
        subtitle: 'Planning et fiches techniques',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EventsScreen(isAdmin: isAdmin)),
        ),
      ),
      _QuickAction(
        icon: Icons.local_shipping_outlined,
        title: 'Transport',
        subtitle: 'Camions et affectations',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TransportScreen(isAdmin: isAdmin)),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SONO SGHAIER'),
        actions: [
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ahlaa, ${user.nomPrenom}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    user.role,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isAdmin
                  ? 'Vue générale de votre activité événementielle.'
                  : 'Mode lecture seule : seul l\'Admin peut modifier.',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 28),
            const _SectionTitle('Gestion de l’entreprise'),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quickActions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) =>
                  _ActionCard(action: quickActions[index]),
            ),
            const SizedBox(height: 30),
            const _SectionTitle('Aujourd’hui & Prochainement'),
            const SizedBox(height: 14),
            const _EventPreviewCard(),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: AppColors.gold, size: 32),
              const SizedBox(height: 14),
              Text(
                action.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                action.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.gold,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _EventPreviewCard extends StatelessWidget {
  const _EventPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Aucun événement critique',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Text(
                    'Stable',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Toutes vos données sont enregistrées sur cet appareil (mode hors-ligne).',
              style: TextStyle(color: AppColors.muted, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}
