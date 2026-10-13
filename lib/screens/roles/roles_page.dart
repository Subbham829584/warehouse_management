import 'package:flutter/material.dart';
import 'package:warehouse_management/models/app_user.dart';
import 'package:warehouse_management/services/wms_service.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class RolesPage extends StatefulWidget {
  const RolesPage({super.key});

  @override
  State<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends State<RolesPage> {
  UserRole _activeRole = UserRole.admin;

  @override
  Widget build(BuildContext context) {
    final wms = WmsService.instance;

    return ListenableBuilder(
      listenable: wms,
      builder: (context, _) {
        final users = wms.users;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Roles & Permissions (RBAC)'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Simulator Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: ColorPalette.nileBlue,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.security, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Role Simulator',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  'Switch roles instantly to test UI access rules',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: UserRole.values.map((role) {
                            final isSel = _activeRole == role;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _activeRole = role),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSel ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    role.label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isSel ? ColorPalette.nileBlue : Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Active Role Permissions Overview
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Permissions for ${_activeRole.label}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ColorPalette.timberGreen),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getRoleColor(_activeRole).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _activeRole.label,
                              style: TextStyle(fontWeight: FontWeight.bold, color: _getRoleColor(_activeRole), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _permTile('Create & Edit Products & Prices', Permissions.canEditProduct(_activeRole)),
                      _permTile('Delete Catalog Products', Permissions.canDeleteProduct(_activeRole)),
                      _permTile('Manage Purchase Orders (PO)', Permissions.canManagePO(_activeRole)),
                      _permTile('Receive Goods (GRN) & Stock In', Permissions.canReceiveStock(_activeRole)),
                      _permTile('Perform Cycle Count Walk', Permissions.canRunCycleCount(_activeRole)),
                      _permTile('Approve Cycle Count Variance (Audit)', Permissions.canApproveCycleCount(_activeRole)),
                      _permTile('Manage Users & Roles (RBAC)', Permissions.canManageUsers(_activeRole)),
                      _permTile('View Warehouse KPI Dashboard', Permissions.canViewKPIs(_activeRole)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Warehouse Team Members
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned Warehouse Staff',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ColorPalette.timberGreen),
                      ),
                      const SizedBox(height: 12),
                      for (final u in users)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: _getRoleColor(u.role).withValues(alpha: 0.15),
                            child: Text(
                              u.displayName.isNotEmpty ? u.displayName[0] : 'U',
                              style: TextStyle(color: _getRoleColor(u.role), fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(u.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(u.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getRoleColor(u.role).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              u.role.label,
                              style: TextStyle(color: _getRoleColor(u.role), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _permTile(String label, bool allowed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            allowed ? Icons.check_circle : Icons.cancel,
            color: allowed ? Colors.green : Colors.red.shade400,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: allowed ? Colors.black87 : Colors.grey.shade500,
                decoration: allowed ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
          Text(
            allowed ? 'Allowed' : 'Restricted',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: allowed ? Colors.green : Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) => switch (role) {
    UserRole.admin => Colors.deepOrange,
    UserRole.manager => ColorPalette.nileBlue,
    UserRole.picker => Colors.teal,
  };
}
