import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../models/invite_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/list_providers.dart';

class InviteScreen extends ConsumerWidget {
  final String inviteId;
  const InviteScreen({super.key, required this.inviteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(listRepositoryProvider);
    final user = ref.watch(authStateProvider).value;

    return FutureBuilder<Invite?>(
      future: ref.read(firestoreServiceProvider).getInviteById(inviteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: Text('Invite not found or expired')));
        }

        final invite = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: const Text("Join Shared List")),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "You’ve been invited to join:",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  invite.listTitle,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.group_add),
                  label: const Text("Accept Invite"),
                  onPressed: () async {
                    if (user == null) return;
                    await repo.acceptInvite(inviteId, user.uid);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Joined successfully!')),
                    );
                    Navigator.pop(context);
                  },
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
