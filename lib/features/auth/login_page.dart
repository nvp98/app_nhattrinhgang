import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nhattrinhgang_mobile/core/stores/localstore.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (ref) => AuthNotifier(),
);

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 800));
    state = const AsyncValue.data(null);
  }
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    final username = _emailCtrl.text.trim();

    await ref.read(authProvider.notifier).signIn(username, _passwordCtrl.text);

    final authState = ref.read(authProvider);

    authState.when(
      data: (_) async {
        // Lưu local
        await LocalStore.saveUsername(username);

        // 👉 THÔNG BÁO THÀNH CÔNG
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đăng nhập thành công'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        // 👉 Delay ngắn rồi chuyển màn
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.go('/home');
      },
      error: (err, _) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${err.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      },
      loading: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00437E), Color(0xFF00529C), Color(0xFF0072C6)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 150,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _HeaderPatternPainter(
                                  background: const Color(0xFF0B2545),
                                  ringColor: Colors.white10,
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 12,
                                        offset: Offset(0, 6)),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Image.asset(
                                    'logo_hoa_phat.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stack) =>
                                        const FlutterLogo(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'NHẬT TRÌNH GANG',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Đăng nhập hệ thống',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              // Text(
                              //   'ĐĂNG NHẬP',
                              //   style: theme.textTheme.headlineMedium,
                              //   textAlign: TextAlign.center,
                              // ),
                              const SizedBox(height: 6),
                              // Text(
                              //   'Sign in to continue.',
                              //   style: theme.textTheme.bodyMedium,
                              //   textAlign: TextAlign.center,
                              // ),
                              const SizedBox(height: 20),
                              Text(
                                'Mã nhân viên / Mã tàu',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailCtrl,
                                enabled: !authState.isLoading,
                                style: const TextStyle(
                                  fontSize: 18,
                                  // fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'VD: HPDQ12345',
                                  prefixIcon: const Icon(Icons.badge_outlined,
                                      size: 28),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                    horizontal: 16,
                                  ),
                                ),
                                textInputAction: TextInputAction.done,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Vui lòng nhập mã nhân viên'
                                    : null,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              const SizedBox(height: 16),
                              // Text(
                              //   'PASSWORD',
                              //   style: theme.textTheme.labelSmall?.copyWith(
                              //       fontWeight: FontWeight.w600,
                              //       color: Colors.grey[700]),
                              // ),
                              // const SizedBox(height: 8),
                              // TextFormField(
                              //   controller: _passwordCtrl,
                              //   decoration: InputDecoration(
                              //     hintText: '••••••••',
                              //     prefixIcon: const Icon(Icons.lock_outline),
                              //     suffixIcon: IconButton(
                              //       onPressed: () =>
                              //           setState(() => _obscure = !_obscure),
                              //       icon: Icon(_obscure
                              //           ? Icons.visibility
                              //           : Icons.visibility_off),
                              //     ),
                              //   ),
                              //   obscureText: _obscure,
                              //   textInputAction: TextInputAction.done,
                              //   validator: (v) => v == null || v.isEmpty
                              //       ? 'Nhập mật khẩu'
                              //       : null,
                              //   onFieldSubmitted: (_) => _submit(),
                              // ),
                              const SizedBox(height: 16),
                              // Align(
                              //   alignment: Alignment.centerRight,
                              //   child: TextButton(
                              //     onPressed: authState.isLoading ? null : () {},
                              //     child: const Text('Quên mật khẩu?'),
                              //   ),
                              // ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed:
                                      authState.isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0B2545),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  child: authState.isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('XÁC NHẬN'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Wrap(
                              //   alignment: WrapAlignment.center,
                              //   spacing: 4,
                              //   children: [
                              //     const Text('Chưa có tài khoản?'),
                              //     TextButton(
                              //       onPressed:
                              //           authState.isLoading ? null : () {},
                              //       child: const Text('Signup!'),
                              //     ),
                              //   ],
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderPatternPainter extends CustomPainter {
  _HeaderPatternPainter({required this.background, required this.ringColor});
  final Color background;
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = background;
    canvas.drawRect(Offset.zero & size, bg);

    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    for (double y = 20; y < size.height + 60; y += 60) {
      for (double x = 20; x < size.width + 60; x += 60) {
        canvas.drawCircle(Offset(x, y), 22, ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
