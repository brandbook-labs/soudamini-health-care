import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/components/index.dart';
import 'role_form_screen.dart';

class RolesListScreen extends StatelessWidget {
  const RolesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final roles = [
      {"name": "Super Admin", "users": 2, "desc": "Full access to all modules"},
      {
        "name": "Clinic Manager",
        "users": 45,
        "desc": "Can manage clinic settings and staff",
      },
      {
        "name": "Support Staff",
        "users": 12,
        "desc": "Can view users and resolve tickets",
      },
    ];

    return Scaffold(
      appBar: const JivanAppBar(title: "Access Roles", showBack: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RoleFormScreen()),
        ),
        child: const Icon(LucideIcons.plus),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: roles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final role = roles[index];
          return Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.shield, color: Colors.purple),
              ),
              title: Text(
                role['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(role['desc'] as String),
              trailing: Text(
                "${role['users']} Users",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoleFormScreen(initialRole: role),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
