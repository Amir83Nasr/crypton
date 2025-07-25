import 'package:crypton_frontend/services/public_api_service.dart';
import 'package:crypton_frontend/services/storage_service.dart';

import 'package:flutter/material.dart';
import 'package:crypton_frontend/theme.dart';

import 'package:crypton_frontend/screens/signup.dart';
import 'package:crypton_frontend/screens/admin/dashboard.dart';
import 'package:crypton_frontend/screens/user/dashboard.dart';

import 'package:crypton_frontend/widgets/custom_snackbar.dart';
import 'package:crypton_frontend/widgets/custom_button.dart';
import 'package:crypton_frontend/widgets/custom_input.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final result = await PublicApiService().login(
      username: username,
      password: password,
    );

    if (result['success'] == true) {
      final userInfo = result['data'];

      final String role = userInfo['role'];
      final String access = userInfo['access'];
      final String refresh = userInfo['refresh'];

      await StorageService.saveTokens(access: access, refresh: refresh);

      showCustomSnackBar(context: context, message: 'ورود با موفقیت انجام شد');

      Widget destination =
          (role == 'admin') ? const AdminDashboard() : const Dashboard();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } else {
      final error = result['error'];
      String message = 'ورود ناموفق';

      if (error is Map) {
        message = error.entries
            .map((e) {
              if (e.value is List) return e.value.join('\n');
              return e.value.toString();
            })
            .join('\n');
      } else if (error is String) {
        message = error;
      }

      showCustomSnackBar(context: context, message: message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final logoAsset =
        isDarkMode
            ? 'assets/icons/icon_light.png'
            : 'assets/icons/icon_dark.png';

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text('ورود به پنل کاربری', style: appTextTheme.titleMedium),
        ),
        centerTitle: true,
        toolbarHeight: 72,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 56),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  logoAsset,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 32),
              CustomInput(
                controller: _usernameController,
                labelText: 'نام کاربری',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'نام کاربری الزامی است';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomInput(
                controller: _passwordController,
                labelText: 'رمز عبور',
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'رمز عبور الزامی است';
                  } else if (value.length < 4) {
                    return 'رمز عبور باید حداقل ۴ کاراکتر باشد';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(text: 'ورود', onPressed: _submit),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Signup()),
                  );
                },
                child: const Text('حساب نداری؟ ثبت‌نام کن'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
