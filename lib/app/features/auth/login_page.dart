import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../initialzation_dependencies.dart';
import 'data/datasources/auth_token_storage.dart';
import 'data/services/auth_service.dart';
import 'data/services/mock_auth_service.dart';
import 'presentation/cubits/auth_cubit.dart';
import 'presentation/cubits/auth_state.dart';
import 'presentation/pages/otp_verification_view.dart';
import 'presentation/pages/phone_input_view.dart';

class LoginPage extends StatelessWidget {
  final AuthService? authService;

  const LoginPage({super.key, this.authService});

  @override
  Widget build(BuildContext context) {
    AuthCubit? existingCubit;
    try {
      existingCubit = context.read<AuthCubit>();
    } catch (_) {}

    if (authService == null && existingCubit != null) {
      return const _LoginPageContent();
    }

    return FutureBuilder<AuthService>(
      future: _resolveAuthService(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        return BlocProvider(
          create: (_) => AuthCubit(authService: snapshot.data!),
          child: const _LoginPageContent(),
        );
      },
    );
  }

  Future<AuthService> _resolveAuthService() async {
    if (authService != null) return authService!;
    if (singelton.isRegistered<AuthService>()) {
      return singelton<AuthService>();
    }
    final prefs = await SharedPreferences.getInstance();
    final storage = SharedPrefsAuthTokenStorage(prefs: prefs);
    final mockService = MockAuthService(tokenStorage: storage);
    singelton.registerSingleton<AuthTokenStorage>(storage);
    singelton.registerSingleton<AuthService>(mockService);
    return mockService;
  }
}

class _LoginPageContent extends StatefulWidget {
  const _LoginPageContent();

  @override
  State<_LoginPageContent> createState() => _LoginPageContentState();
}

class _LoginPageContentState extends State<_LoginPageContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        try {
          final location = GoRouterState.of(context).uri.toString();
          if (location != '/login' && location != '/') return;
        } catch (_) {}
        final authState = context.read<AuthCubit>().state;
        if (authState.status == AuthStatus.authenticated) {
          _redirectBasedOnRoles(context, authState.roles);
        }
      } catch (_) {}
    });
  }

  static void _redirectBasedOnRoles(
    BuildContext context,
    List<String> rawRoles,
  ) {
    final roles = rawRoles.map((r) => r.toLowerCase().trim()).toList();
    if (roles.contains('admin')) {
      context.go('/admin/dashboard');
    } else if (roles.contains('restaurant')) {
      try {
        context.go('/restaurant/dashboard');
      } catch (_) {
        context.go('/store/dashboard');
      }
    } else if (roles.contains('store') || roles.contains('retail')) {
      context.go('/store/dashboard');
    } else if (roles.contains('delivery')) {
      context.go('/delivery/orders');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          (current.status == AuthStatus.authenticated ||
              current.status == AuthStatus.guest),
      listener: (context, state) {
        try {
          try {
            final location = GoRouterState.of(context).uri.toString();
            if (location != '/login' && location != '/') return;
          } catch (_) {}

          if (state.status == AuthStatus.authenticated) {
            _redirectBasedOnRoles(context, state.roles);
          } else if (state.status == AuthStatus.guest) {
            context.go('/home');
          }
        } catch (_) {
          // Fallback when executed outside GoRouter harness
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: BlocBuilder<AuthCubit, AuthState>(
            buildWhen: (previous, current) => previous.step != current.step,
            builder: (context, state) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                transitionBuilder: (child, animation) {
                  final inFromRight = Tween<Offset>(
                    begin: const Offset(0.08, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: inFromRight,
                      child: child,
                    ),
                  );
                },
                child: state.step == AuthStep.login
                    ? const KeyedSubtree(
                        key: ValueKey('phone_input_view'),
                        child: PhoneInputView(),
                      )
                    : const KeyedSubtree(
                        key: ValueKey('otp_verification_view'),
                        child: OtpVerificationView(),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}
