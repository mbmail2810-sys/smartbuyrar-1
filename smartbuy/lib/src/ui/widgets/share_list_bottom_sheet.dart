import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/grocery_list.dart';
import '../../providers/auth_providers.dart';
import '../../providers/list_providers.dart';

class ShareListBottomSheet extends ConsumerStatefulWidget {
  final GroceryList list;

  const ShareListBottomSheet({super.key, required this.list});

  @override
  ConsumerState<ShareListBottomSheet> createState() => _ShareListBottomSheetState();
}

class _ShareListBottomSheetState extends ConsumerState<ShareListBottomSheet> {
  final _emailController = TextEditingController();
  MemberRole _selectedRole = MemberRole.editor;
  bool _isLoading = false;
  String? _inviteLink;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _createInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).value!;
      final repo = ref.read(listRepositoryProvider);
      
      final inviteId = await repo.createInviteWithEmail(
        listId: widget.list.id,
        listTitle: widget.list.title,
        createdBy: user.uid,
        invitedUserEmail: email,
        role: _selectedRole.name,
      );

      final link = "smartbuy://invite/$inviteId";
      setState(() {
        _inviteLink = link;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite created successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _copyInviteLink() async {
    if (_inviteLink == null) {
      final user = ref.read(authStateProvider).value!;
      final repo = ref.read(listRepositoryProvider);
      
      setState(() => _isLoading = true);
      
      try {
        final inviteId = await repo.createInvite(
          listId: widget.list.id,
          listTitle: widget.list.title,
          createdBy: user.uid,
          role: _selectedRole.name,
        );
        
        final link = "smartbuy://invite/$inviteId";
        await Clipboard.setData(ClipboardData(text: link));
        
        setState(() {
          _inviteLink = link;
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invite link copied to clipboard!')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    } else {
      await Clipboard.setData(ClipboardData(text: _inviteLink!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link copied to clipboard!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final isOwner = widget.list.isOwner(currentUser?.uid ?? '');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.share, color: Color(0xFF00B200)),
              const SizedBox(width: 10),
              Text(
                'Share "${widget.list.title}"',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Enter email address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00B200), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Select Role',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _RoleOption(
                  role: MemberRole.editor,
                  label: 'Editor',
                  description: 'Can add, edit, delete items',
                  icon: Icons.edit,
                  isSelected: _selectedRole == MemberRole.editor,
                  onTap: () => setState(() => _selectedRole = MemberRole.editor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoleOption(
                  role: MemberRole.viewer,
                  label: 'Viewer',
                  description: 'Can only view items',
                  icon: Icons.visibility,
                  isSelected: _selectedRole == MemberRole.viewer,
                  onTap: () => setState(() => _selectedRole = MemberRole.viewer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _copyInviteLink,
                  icon: const Icon(Icons.link),
                  label: const Text('Copy Link'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF00B200)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createInvite,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 16, 
                        height: 16, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      )
                    : const Icon(Icons.send),
                  label: const Text('Send Invite'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B200),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (widget.list.members.length > 1) ...[
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Current Members (${widget.list.members.length})',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...widget.list.members.map((memberId) {
              final role = widget.list.getRoleForUser(memberId);
              final isCurrentUser = memberId == currentUser?.uid;
              final isMemberOwner = role == MemberRole.owner;
              
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF00B200).withOpacity(0.1),
                  child: Icon(
                    isMemberOwner ? Icons.star : Icons.person,
                    color: const Color(0xFF00B200),
                    size: 20,
                  ),
                ),
                title: Text(
                  isCurrentUser ? 'You' : 'Member',
                  style: TextStyle(
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(role.name.toUpperCase(), style: const TextStyle(fontSize: 11)),
                trailing: isOwner && !isMemberOwner && !isCurrentUser
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () async {
                        final repo = ref.read(listRepositoryProvider);
                        await repo.removeMember(widget.list.id, memberId);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Member removed')),
                          );
                        }
                      },
                    )
                  : null,
              );
            }),
          ],
          
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final MemberRole role;
  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.role,
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00B200).withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00B200) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00B200) : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF00B200) : Colors.black87,
              ),
            ),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
