import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

final _usersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) {
  return UserRepository().getAll();
});

final _repo = UserRepository();

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(_usersProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Users', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New User'),
                  onPressed: () => _showForm(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: usersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (users) => users.isEmpty
                    ? const Center(child: Text('No users'))
                    : ListView(
                        children: users.map((u) => Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text(u.fullName[0])),
                            title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('@${u.username} · ${u.role}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!u.isActive)
                                  const Chip(label: Text('Inactive', style: TextStyle(fontSize: 11, color: Colors.white)), backgroundColor: Colors.red, padding: EdgeInsets.zero, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, labelPadding: EdgeInsets.symmetric(horizontal: 6)),
                                const SizedBox(width: 4),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _showForm(context, user: u);
                                    if (v == 'delete') _confirmDelete(context, u);
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showForm(BuildContext context, {UserModel? user}) async {
    final nameCtrl = TextEditingController(text: user?.fullName ?? '');
    final userCtrl = TextEditingController(text: user?.username ?? '');
    final passCtrl = TextEditingController();
    String role = user?.role ?? 'Admin';
    bool saving = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user == null ? 'New User' : 'Edit User',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 8),
                TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username')),
                const SizedBox(height: 8),
                TextField(controller: passCtrl, decoration: InputDecoration(labelText: user == null ? 'Password' : 'New Password (leave empty to keep)'), obscureText: true),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Role'),
                  initialValue: role,
                  items: const [
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                    DropdownMenuItem(value: 'Reception', child: Text('Reception')),
                  ],
                  onChanged: (v) => setSheetState(() => role = v!),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      setSheetState(() => saving = true);
                      try {
                        if (user == null) {
                          await _repo.create(
                            username: userCtrl.text,
                            password: passCtrl.text,
                            fullName: nameCtrl.text,
                            role: role,
                          );
                        } else {
                          await _repo.update(
                            user.id,
                            fullName: nameCtrl.text,
                            password: passCtrl.text.isNotEmpty ? passCtrl.text : null,
                            role: role,
                          );
                        }
                        Navigator.pop(ctx, true);
                      } catch (e) {
                        setSheetState(() => saving = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    },
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(user == null ? 'Create' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );

    if (result == true) ref.invalidate(_usersProvider);
  }

  Future<void> _confirmDelete(BuildContext context, UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Deactivate "${user.fullName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Deactivate', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _repo.delete(user.id);
        ref.invalidate(_usersProvider);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
