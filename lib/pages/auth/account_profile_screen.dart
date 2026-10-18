import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/local_profile.dart';
import '../../widgets/common/note_card.dart';

class AccountProfileScreen extends StatefulWidget {
  const AccountProfileScreen({
    super.key,
    required this.profile,
    required this.onNameChanged,
    required this.onSignOut,
  });

  final LocalProfile profile;
  final Future<LocalProfile> Function(String name) onNameChanged;
  final Future<void> Function() onSignOut;

  @override
  State<AccountProfileScreen> createState() => _AccountProfileScreenState();
}

class _AccountProfileScreenState extends State<AccountProfileScreen> {
  late LocalProfile _profile = widget.profile;
  bool _isSaving = false;

  Future<void> _editName() async {
    final controller = TextEditingController(text: _profile.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah nama profil'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nama lengkap'),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().length >= 2) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !mounted) return;
    setState(() => _isSaving = true);
    try {
      final profile = await widget.onNameChanged(name);
      if (mounted) setState(() => _profile = profile);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _memberSince() {
    final date = DateTime.tryParse(_profile.createdAt)?.toLocal();
    if (date == null) return 'Tanggal tidak tersedia';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil saya')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxAuthCardWidth),
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.surfaceGreenLight,
                      child: Text(
                        _profile.name.isEmpty ? '?' : _profile.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.forest,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _profile.name,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_profile.email,
                              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                          const SizedBox(height: 12),
                          Text('Bergabung ${_memberSince()}',
                              style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _editName,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Ubah nama'),
              ),
              const SizedBox(height: 8),
              const NoteCard(
                text:
                    'Profil dan progres akun ini tersimpan di perangkat ini. Akun tidak tersinkron ke server atau perangkat lain.',
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _isSaving ? null : widget.onSignOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar dari akun'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
