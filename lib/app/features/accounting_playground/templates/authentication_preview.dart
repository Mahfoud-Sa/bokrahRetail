import 'package:flutter/material.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import '../components.dart';

class AuthenticationPreview extends StatefulWidget {
  const AuthenticationPreview({super.key});
  @override
  State<AuthenticationPreview> createState() => _AuthenticationPreviewState();
}

class _AuthenticationPreviewState extends State<AuthenticationPreview> {
  final form = GlobalKey<FormState>();
  bool visible = false, loading = false, fail = false;
  String? result;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: BkCard(
        child: Form(
          key: form,
          child: BkColumn(
            children: [
              Text('Bokrah', style: Theme.of(context).textTheme.headlineLarge),
              Text(
                tr(
                  context,
                  'Demo sign-in. Use sample values only.',
                  'دخول تجريبي. استخدم قيماً تجريبية فقط.',
                ),
              ),
              TextFormField(
                initialValue: 'demo@bokrah.example',
                decoration: InputDecoration(
                  labelText: tr(context, 'Email', 'البريد الإلكتروني'),
                ),
                validator: (v) =>
                    v != null &&
                        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)
                    ? null
                    : tr(
                        context,
                        'Enter a valid email.',
                        'أدخل بريداً صحيحاً.',
                      ),
              ),
              TextFormField(
                initialValue: 'sample123',
                obscureText: !visible,
                decoration: InputDecoration(
                  labelText: tr(context, 'Password', 'كلمة المرور'),
                  suffixIcon: IconButton(
                    tooltip: tr(
                      context,
                      visible ? 'Hide password' : 'Show password',
                      visible ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور',
                    ),
                    onPressed: () => setState(() => visible = !visible),
                    icon: Icon(
                      visible ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
                validator: (v) => (v?.length ?? 0) >= 8
                    ? null
                    : tr(
                        context,
                        'Use at least 8 characters.',
                        'استخدم ٨ أحرف على الأقل.',
                      ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  tr(context, 'Simulate sign-in error', 'محاكاة خطأ الدخول'),
                ),
                value: fail,
                onChanged: (v) => setState(() => fail = v),
              ),
              if (result != null)
                Semantics(liveRegion: true, child: Text(result!)),
              BkButton(
                label: tr(context, 'Sign in to preview', 'الدخول للمعاينة'),
                loading: loading,
                loadingLabel: tr(context, 'Checking sample', 'جارٍ فحص المثال'),
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  setState(() => loading = true);
                  await Future<void>.delayed(const Duration(milliseconds: 600));
                  if (!mounted) return;
                  setState(() {
                    loading = false;
                    result = fail
                        ? tr(
                            context,
                            'Sample sign-in failed. Try again.',
                            'فشل الدخول التجريبي. أعد المحاولة.',
                          )
                        : tr(
                            context,
                            'Demo complete. No account or session was created.',
                            'اكتملت المعاينة. لم يُنشأ حساب أو جلسة.',
                          );
                  });
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
