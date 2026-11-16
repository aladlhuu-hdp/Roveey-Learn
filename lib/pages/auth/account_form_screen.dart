import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_error_mapper.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/eyebrow.dart';
import '../../widgets/mangrove_scene/mangrove_scene.dart';
import 'login_screen.dart';
import 'widgets/auth_text_field.dart';

class AccountFormScreen extends StatefulWidget {
  const AccountFormScreen({
    super.key,
    required this.isRegister,
    required this.onAuthenticated,
    this.authService,
  });

  final bool isRegister;
  final LocalProfileCallback onAuthenticated;
  final AuthService? authService;

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmationController = TextEditingController();
  late final AuthService _authService;
  bool _passwordVisible = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authService = widget.authService ?? context.read<AuthService>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final profile = widget.isRegister
          ? await _authService.register(
              name: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
            )
          : await _authService.signIn(
              email: _emailController.text,
              password: _passwordController.text,
            );
      if (!mounted) return;
      await widget.onAuthenticated(profile);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = AppErrorMapper.toUserMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _continueWithoutAccount() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = widget.isRegister;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppConstants.maxAuthCardWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.forest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.spa_rounded, color: AppColors.accentMint, size: 24),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'ROOVEYLEARN',
                            style: TextStyle(
                              color: AppColors.forestDeep,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'BELAJAR UNTUK PESISIR',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: isRegister ? 'Kembali ke masuk' : 'Lanjut tanpa akun',
                      onPressed: isRegister
                          ? () => Navigator.of(context).maybePop()
                          : _continueWithoutAccount,
                      icon: Icon(
                        isRegister ? Icons.arrow_back_rounded : Icons.close_rounded,
                        color: AppColors.forest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: const MangroveScene(height: 142, showHotspots: false, compact: true),
                ),
                const SizedBox(height: 25),
                Eyebrow(label: isRegister ? 'MULAI PERJALANANMU' : 'AKUN ROOVEYLEARN'),
                const SizedBox(height: 8),
                Text(
                  isRegister ? 'Buat akun baru.' : 'Selamat datang\nkembali.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 7),
                Text(
                  isRegister
                      ? 'Siapkan ruang untuk menyimpan perjalanan belajarmu.'
                      : 'Masuk untuk melanjutkan perjalanan menjaga pesisir.',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 22),
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      if (isRegister) ...<Widget>[
                        AuthTextField(
                          label: 'Nama lengkap',
                          icon: Icons.person_outline_rounded,
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          autofillHints: const <String>[AutofillHints.name],
                          validator: (value) => (value == null || value.trim().length < 2)
                              ? 'Masukkan nama minimal 2 karakter.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      AuthTextField(
                        label: 'Email',
                        icon: Icons.mail_outline_rounded,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[AutofillHints.email],
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                              ? null
                              : 'Masukkan alamat email yang valid.';
                        },
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        label: 'Kata sandi',
                        icon: Icons.lock_outline_rounded,
                        controller: _passwordController,
                        textInputAction: isRegister ? TextInputAction.next : TextInputAction.done,
                        autofillHints: <String>[
                          isRegister ? AutofillHints.newPassword : AutofillHints.password
                        ],
                        obscureText: !_passwordVisible,
                        suffixIcon: IconButton(
                          tooltip: _passwordVisible ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi',
                          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                          ),
                        ),
                        validator: (value) =>
                            (value == null || value.length < 8) ? 'Kata sandi minimal 8 karakter.' : null,
                      ),
                      if (isRegister) ...<Widget>[
                        const SizedBox(height: 14),
                        AuthTextField(
                          label: 'Ulangi kata sandi',
                          icon: Icons.lock_reset_rounded,
                          controller: _confirmationController,
                          textInputAction: TextInputAction.done,
                          obscureText: !_passwordVisible,
                          suffixIcon: IconButton(
                            tooltip:
                                _passwordVisible ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi',
                            onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 20,
                            ),
                          ),
                          validator: (value) =>
                              value != _passwordController.text ? 'Kata sandi belum cocok.' : null,
                        ),
                      ],
                      if (!isRegister)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Kata sandi lokal tidak dapat dipulihkan. Kata sandi tidak disimpan oleh aplikasi.'),
                              ),
                            ),
                            child: const Text('Lupa kata sandi?'),
                          ),
                        )
                      else
                        const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(isRegister ? 'Buat akun' : 'Masuk'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      isRegister ? 'Sudah punya akun?' : 'Belum punya akun?',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => isRegister
                                ? LoginScreen(
                                    onAuthenticated: widget.onAuthenticated,
                                    authService: _authService,
                                  )
                                : RegisterScreen(
                                    onAuthenticated: widget.onAuthenticated,
                                    authService: _authService,
                                  ),
                          ),
                        );
                      },
                      child: Text(isRegister ? 'Masuk' : 'Daftar'),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(_errorMessage!,
                      style: const TextStyle(color: AppColors.errorDark, fontSize: 12)),
                ],
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceInfoGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.info_outline_rounded, color: AppColors.forest, size: 18),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Akun tersimpan hanya di perangkat ini. Kata sandi tidak disimpan, dan akun tidak tersinkron ke server.',
                          style: TextStyle(color: AppColors.forestDeep, fontSize: 11, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: _continueWithoutAccount,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('Lanjutkan tanpa akun'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
