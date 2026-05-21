import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _codeSent = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length != 11) {
      setState(() => _error = '请输入正确的手机号');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      if (_isLogin) {
        final pwd = _passwordController.text;
        if (pwd.isEmpty) {
          setState(() => _error = '请输入密码');
          setState(() => _isLoading = false);
          return;
        }
        await ref.read(authProvider.notifier).login(phone, pwd);
      } else {
        final code = _codeController.text.trim();
        if (code.isEmpty) {
          setState(() => _error = '请输入验证码');
          setState(() => _isLoading = false);
          return;
        }
        final pwd = _passwordController.text;
        if (pwd.length < 6) {
          setState(() => _error = '密码至少6位');
          setState(() => _isLoading = false);
          return;
        }
        await ref.read(authProvider.notifier).register(phone, code, pwd);
      }
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 11) {
      setState(() => _error = '请输入正确的手机号');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).sendSmsCode(phone);
      setState(() => _codeSent = true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Icon(Icons.shopping_bag_outlined, size: 56,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(_isLogin ? '登录' : '注册',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 32),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: InputDecoration(
                  labelText: '手机号',
                  hintText: '请输入手机号',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: '验证码',
                          hintText: '6位验证码',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonal(
                      onPressed: _isLoading ? null : _sendCode,
                      child: Text(_codeSent ? '已发送' : '获取验证码'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '密码',
                  hintText: _isLogin ? '请输入密码' : '请设置密码（至少6位）',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: Text(_isLoading ? '请稍候...' : (_isLogin ? '登录' : '注册')),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() { _isLogin = !_isLogin; _codeSent = false; _error = null; });
                },
                child: Text(_isLogin ? '没有账号？去注册' : '已有账号？去登录'),
              ),
              const SizedBox(height: 24),
              Text('Demo: 手机号 11111111111 密码 298556',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
