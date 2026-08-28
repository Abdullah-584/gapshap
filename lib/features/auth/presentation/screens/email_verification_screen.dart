import '../../../../core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';

class EmailVerificationScreen extends ConsumerWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 80),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 40,
                  color: AppColors.textOnPrimary,
                ),
              ).animate().fadeIn().scale(),
              const SizedBox(height: 24),
              Text(
                'Verify your email',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              Text(
                'We\'ve sent a verification link to your email.\nPlease check your inbox and click the link.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
              ).animate().fadeIn(delay: 300.ms),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Back to Sign In'),
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  // Resend verification email
                  context.showSuccessSnackBar('Verification email resent!');
                },
                child: const Text('Resend verification email'),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
