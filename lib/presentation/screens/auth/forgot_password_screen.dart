import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/error/app_error.dart';
import '../../providers/app_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(_emailController.text.trim());
      
      setState(() => _emailSent = true);
    } on AppError catch (e) {
      _showErrorSnackBar(e.message);
    } catch (e) {
      _showErrorSnackBar('Error al enviar email de recuperación');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: AppTheme.paddingLarge,
          child: Column(
            children: [
              const SizedBox(height: 48),
              
              if (!_emailSent) ...[
                // Logo
                GlassContainer(
                  width: 80,
                  height: 80,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
                  gradient: AppTheme.accentGradient,
                  child: const Icon(
                    Icons.lock_reset,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Recuperar Contraseña',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Te enviaremos un enlace para restablecer tu contraseña',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Form
                GlassCard(
                  padding: AppTheme.paddingLarge,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleResetPassword(),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'tu@email.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu email';
                            }
                            if (!value.contains('@')) {
                              return 'Ingresa un email válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        // Send button
                        GlassButton(
                          onPressed: _isLoading ? null : _handleResetPassword,
                          isLoading: _isLoading,
                          height: 56,
                          child: const Text('Enviar Email'),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Success state
                GlassContainer(
                  width: 100,
                  height: 100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
                  backgroundColor: AppTheme.successColor.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 60,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Email Enviado',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                GlassButton(
                  onPressed: () => context.go('/auth/login'),
                  isOutlined: true,
                  height: 56,
                  child: const Text('Volver al Login'),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Back to login
              if (!_emailSent)
                TextButton(
                  onPressed: () => context.go('/auth/login'),
                  child: const Text('Volver al login'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
