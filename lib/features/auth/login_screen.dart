import 'package:flutter/material.dart';
import 'package:hvac_admin/core/auth/management_sign_in_result.dart';
import 'package:hvac_admin/core/config/demo_credentials.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/l10n/admin_strings.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/shared/widgets/language_toggle.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _email;
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(
      text: DemoCredentials.showLoginHints ? DemoCredentials.adminEmail : '',
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _messageFor(ManagementSignInError error, AdminStrings strings) => switch (error) {
        ManagementSignInError.invalidCredentials => strings.invalidCredentials,
        ManagementSignInError.technicianNotAllowed => strings.technicianNotAllowed,
        ManagementSignInError.profileNotFound => strings.profileNotFound,
        ManagementSignInError.accountDisabled => strings.accountDisabled,
      };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<ManagementAuthController>();
    final strings = adminStringsRead(context);
    setState(() => _error = null);
    final ok = await auth.signIn(email: _email.text, password: _password.text);
    if (!mounted) return;
    if (!ok) {
      final err = auth.lastSignInError ?? ManagementSignInError.invalidCredentials;
      setState(() => _error = _messageFor(err, strings));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ManagementAuthController>();
    final strings = adminStrings(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppBrandMark(size: 64)),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      strings.officeSignIn,
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      strings.officeSignInSubtitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const LanguageToggle(compact: true),
                    const SizedBox(height: AppSpacing.xxl),
                    AppTextField(
                      controller: _email,
                      label: strings.email,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.mail_outline,
                      autocorrect: false,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? strings.emailRequired : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _password,
                      label: strings.password,
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,
                      validator: (v) => (v == null || v.isEmpty) ? strings.passwordRequired : null,
                      onFieldSubmitted: (_) => auth.isBusy ? null : _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 14)),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    AppPrimaryButton(
                      label: strings.signIn,
                      expanded: true,
                      isLoading: auth.isBusy,
                      onPressed: auth.isBusy ? null : _submit,
                    ),
                    if (DemoCredentials.showLoginHints) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        DemoCredentials.loginHint,
                        style: AppTypography.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
