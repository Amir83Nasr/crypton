import 'package:flutter/material.dart';
import 'package:crypton_frontend/theme.dart';

import 'package:crypton_frontend/services/public_api_service.dart';
import 'package:crypton_frontend/screens/user/dashboard.dart';
import 'package:crypton_frontend/screens/login.dart';

import 'package:crypton_frontend/widgets/custom_button.dart';
import 'package:crypton_frontend/widgets/custom_dropdown.dart';
import 'package:crypton_frontend/widgets/custom_input.dart';
import 'package:crypton_frontend/widgets/custom_snackbar.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _ageController;

  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _ageController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedAge = int.tryParse(_ageController.text);
    if (parsedAge == null) {
      showCustomSnackBar(
        context: context,
        message: 'سن وارد شده معتبر نیست',
        isError: true,
      );
      return;
    }

    if (_selectedGender == null || _selectedGender!.isEmpty) {
      showCustomSnackBar(
        context: context,
        message: 'لطفاً جنسیت را انتخاب کنید',
        isError: true,
      );
      return;
    }

    final result = await PublicApiService().register(
      name: _firstNameController.text.trim(),
      family: _lastNameController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      age: parsedAge,
      gender: _selectedGender!,
    );

    if (result['success'] == true) {
      showCustomSnackBar(
        context: context,
        message: 'ثبت‌نام با موفقیت انجام شد',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dashboard()),
      );
    } else {
      final message = parseErrorMessage(result['error']);
      showCustomSnackBar(context: context, message: message, isError: true);
    }
  }

  String parseErrorMessage(dynamic error) {
    if (error is Map<String, dynamic>) {
      // بررسی خطاهای فیلدی، مثل username
      for (final field in [
        'username',
        'password',
        'age',
        'gender',
        'name',
        'family',
      ]) {
        if (error.containsKey(field) &&
            error[field] is List &&
            error[field].isNotEmpty) {
          return error[field].first.toString();
        }
      }

      // بررسی خطاهای غیر فیلدی
      if (error.containsKey('non_field_errors') &&
          error['non_field_errors'] is List &&
          error['non_field_errors'].isNotEmpty) {
        return error['non_field_errors'].first.toString();
      }

      // اگر کلید detail موجود بود
      if (error.containsKey('detail')) {
        return error['detail'].toString();
      }

      // بازگشت اولین پیام خطا موجود در دیکشنری
      if (error.isNotEmpty) {
        final firstValue = error.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
        return firstValue.toString();
      }
    }

    if (error is String) {
      // چک کردن متن خطا برای پیام‌های معمول
      if (error.toLowerCase().contains('username')) {
        return 'این نام کاربری قبلاً ثبت شده است';
      }
      if (error.toLowerCase().contains('password')) {
        return 'رمز عبور وارد شده معتبر نیست';
      }
      return error;
    }

    return 'خطای ناشناخته‌ای رخ داده است';
  }

  String? _requiredValidator(String? value, String fieldName) {
    return (value == null || value.trim().isEmpty)
        ? '$fieldName الزامی است'
        : null;
  }

  String? _usernameValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'نام کاربری الزامی است';
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9._]{3,19}$').hasMatch(value.trim())) {
      return 'نام کاربری باید با حرف شروع شود و بین ۴ تا ۲۰ کاراکتر باشد';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'رمز عبور الزامی است';
    if (value.length < 4) return 'رمز عبور باید حداقل ۴ کاراکتر باشد';
    return null;
  }

  String? _ageValidator(String? value) {
    final age = int.tryParse(value ?? '');
    if (age == null || age < 10 || age > 100) {
      return 'سن معتبر وارد کنید (بین ۱۰ تا ۱۰۰)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final logoAsset =
        Theme.of(context).brightness == Brightness.dark
            ? 'assets/icons/icon_light.png'
            : 'assets/icons/icon_dark.png';

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text('ثبت‌نام در پنل کاربری', style: appTextTheme.titleMedium),
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
              const SizedBox(height: 24),
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
                controller: _firstNameController,
                labelText: 'نام',
                validator: (v) => _requiredValidator(v, 'نام'),
              ),
              const SizedBox(height: 16),

              CustomInput(
                controller: _lastNameController,
                labelText: 'نام خانوادگی',
                validator: (v) => _requiredValidator(v, 'نام خانوادگی'),
              ),
              const SizedBox(height: 16),

              CustomInput(
                controller: _usernameController,
                labelText: 'نام کاربری',
                validator: _usernameValidator,
              ),
              const SizedBox(height: 16),

              CustomInput(
                controller: _passwordController,
                labelText: 'رمز عبور',
                obscureText: true,
                validator: _passwordValidator,
              ),
              const SizedBox(height: 16),

              CustomInput(
                controller: _ageController,
                labelText: 'سن',
                keyboardType: TextInputType.number,
                validator: _ageValidator,
              ),
              const SizedBox(height: 16),

              CustomDropdownInput<String>(
                labelText: 'جنسیت',
                initialValue: _selectedGender,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('آقا')),
                  DropdownMenuItem(value: 'female', child: Text('خانم')),
                ],
                validator:
                    (value) =>
                        (value == null || value.isEmpty)
                            ? 'لطفاً جنسیت را انتخاب کنید'
                            : null,
                onChanged: (value) => setState(() => _selectedGender = value),
              ),
              const SizedBox(height: 24),

              CustomButton(text: 'ثبت‌نام', onPressed: _submit),
              const SizedBox(height: 16),

              TextButton(
                onPressed:
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const Login()),
                    ),
                child: const Text('حساب داری؟ وارد شو'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
