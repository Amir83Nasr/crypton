import 'package:crypton_frontend/screens/user/announcement.dart';
import 'package:crypton_frontend/services/auth_api_service.dart';
import 'package:crypton_frontend/services/public_api_service.dart';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypton_frontend/theme.dart';

import 'package:crypton_frontend/screens/login.dart';

import 'package:crypton_frontend/widgets/custom_dropdown.dart';
import 'package:crypton_frontend/widgets/custom_snackbar.dart';
import 'package:crypton_frontend/widgets/custom_modal.dart';
import 'package:crypton_frontend/widgets/custom_button.dart';
import 'package:crypton_frontend/widgets/custom_input.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();

  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('themeMode') ?? 'system';
    setState(() {
      if (theme == 'light') {
        _themeMode = ThemeMode.light;
      } else if (theme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    });
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    await saveThemeMode(mode);
    setState(() {
      _themeMode = mode;
    });
  }

  void _showRatingModal() {
    int rating = 0;
    final TextEditingController messageController = TextEditingController();
    bool isLoading = false;

    showCustomBottomModal(
      context: context,
      child: StatefulBuilder(
        builder:
            (context, setState) => Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('امتیازدهی و ارسال پیام', style: appTextTheme.titleMedium),
                const SizedBox(height: 16),

                Text(
                  'لطفاً میزان رضایت خود را از برنامه مشخص کنید:',
                  style: appTextTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final reversedIndex = 4 - index;
                      return IconButton(
                        icon: Icon(
                          reversedIndex < rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = reversedIndex + 1;
                          });
                        },
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 16),

                CustomInput(
                  controller: messageController,
                  labelText: 'پیام شما به ادمین',
                ),

                const SizedBox(height: 24),

                isLoading
                    ? const CircularProgressIndicator()
                    : CustomButton(
                      text: 'ثبت امتیاز و ارسال پیام',
                      onPressed: () async {
                        if (rating == 0) {
                          showCustomSnackBar(
                            context: context,
                            message: 'لطفاً ابتدا امتیاز خود را انتخاب کنید.',
                          );
                          return;
                        }

                        setState(() => isLoading = true);

                        try {
                          final response = await AuthApiService()
                              .sendContactMessage(
                                message: messageController.text.trim(),
                                stars: rating,
                              );

                          Navigator.pop(context);

                          showCustomSnackBar(
                            context: context,
                            message:
                                response['message'] ??
                                'امتیاز و پیام شما با موفقیت ارسال شد.',
                          );
                        } catch (e) {
                          showCustomSnackBar(
                            context: context,
                            message:
                                'خطا در ارسال پیام، لطفاً دوباره تلاش کنید.',
                          );
                        } finally {
                          setState(() => isLoading = false);
                        }
                      },
                    ),
              ],
            ),
      ),
    );
  }

  void _showChangePasswordModal() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    String? currentPasswordError;
    String? newPasswordError;
    String? confirmPasswordError;
    bool isLoading = false;

    showCustomBottomModal(
      context: context,
      child: StatefulBuilder(
        builder:
            (context, setState) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('تغییر رمز عبور', style: appTextTheme.titleMedium),
                  const SizedBox(height: 16),

                  CustomInput(
                    controller: currentPasswordController,
                    labelText: 'رمز عبور فعلی',
                    obscureText: true,
                    errorText: currentPasswordError,
                  ),
                  const SizedBox(height: 16),

                  CustomInput(
                    controller: newPasswordController,
                    labelText: 'رمز عبور جدید',
                    obscureText: true,
                    errorText: newPasswordError,
                  ),
                  const SizedBox(height: 16),

                  CustomInput(
                    controller: confirmPasswordController,
                    labelText: 'تأیید رمز جدید',
                    obscureText: true,
                    errorText: confirmPasswordError,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: isLoading ? 'در حال ارسال...' : 'ذخیره تغییرات',
                    onPressed: () async {
                      setState(() {
                        currentPasswordError = null;
                        newPasswordError = null;
                        confirmPasswordError = null;
                      });

                      final oldPass = currentPasswordController.text.trim();
                      final newPass = newPasswordController.text.trim();
                      final confirmPass = confirmPasswordController.text.trim();

                      bool hasError = false;

                      if (oldPass.isEmpty) {
                        currentPasswordError = 'رمز فعلی را وارد کنید';
                        hasError = true;
                      }

                      if (newPass.length < 4) {
                        newPasswordError = 'رمز جدید باید حداقل ۴ کاراکتر باشد';
                        hasError = true;
                      }

                      if (newPass != confirmPass) {
                        confirmPasswordError =
                            'رمز جدید و تایید آن مطابقت ندارند';
                        hasError = true;
                      }

                      if (hasError) {
                        setState(() {}); // آپدیت کردن ارورها
                        return;
                      }

                      try {
                        setState(() => isLoading = true);

                        final response = await AuthApiService().changePassword(
                          oldPassword: oldPass,
                          newPassword: newPass,
                        );

                        Navigator.pop(context);

                        showCustomSnackBar(
                          context: context,
                          message:
                              response['message'] ?? 'رمز با موفقیت تغییر یافت',
                        );
                      } catch (e) {
                        final errorText = e.toString();

                        if (errorText.contains('رمز فعلی نادرست')) {
                          currentPasswordError = 'رمز فعلی اشتباه است';
                        } else {
                          newPasswordError =
                              'خطا در تغییر رمز، لطفاً دوباره تلاش کنید';
                        }

                        setState(() {});
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
                  ),
                ],
              ),
            ),
      ),
    );
  }

  void _showContactUsModal() {
    final TextEditingController messageController = TextEditingController();

    showCustomBottomModal(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('ارتباط با ما', style: appTextTheme.titleMedium),

          const SizedBox(height: 16),

          Text(
            'در صورت وجود پیشنهاد، انتقاد یا سوال، لطفاً پیام خود را وارد کنید:',
            style: appTextTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          CustomInput(controller: messageController, labelText: 'متن پیام شما'),
          const SizedBox(height: 16),

          CustomButton(
            text: 'ارسال پیام',
            onPressed: () {
              Navigator.pop(context);
              showCustomSnackBar(
                context: context,
                message: 'پیام شما با موفقیت ارسال شد.',
              );
              // اگر خواستی به سرور یا ایمیل ارسال بشه، بگو تا اونم اضافه کنم.
            },
          ),

          const SizedBox(height: 24),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اطلاعات تماس:',
                style: appTextTheme.bodyLarge,
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.mail, size: 20),
                  SizedBox(width: 8),
                  Text('support@crypton.app'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.phone, size: 20),
                  SizedBox(width: 8),
                  Text('۹۰۹۲۳۰۱۰۳۰'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToAnnouncementsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Announcement()),
    );
  }

  void _showEditUserModal() async {
    final response = await AuthApiService().getMe();
    final user = response['data'];

    // کنترلرها رو خارج از StatefulBuilder تعریف می‌کنیم
    final TextEditingController nameController = TextEditingController(
      text: user['name'] ?? '',
    );
    final TextEditingController familyController = TextEditingController(
      text: user['family'] ?? '',
    );
    final TextEditingController usernameController = TextEditingController(
      text: user['username'] ?? '',
    );
    final TextEditingController ageController = TextEditingController(
      text: user['age']?.toString() ?? '',
    );

    Map<String, String> genderMapEnToFa = {'male': 'مرد', 'female': 'زن'};
    Map<String, String> genderMapFaToEn = {'مرد': 'male', 'زن': 'female'};

    String genderFromApi = user['gender'] ?? 'male';
    String? selectedGender = genderMapEnToFa[genderFromApi] ?? 'مرد';

    final formKey = GlobalKey<FormState>();

    String? errorText;
    bool isLoading = false;

    showCustomBottomModal(
      context: context,
      child: StatefulBuilder(
        builder:
            (context, setState) => SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'ویرایش اطلاعات کاربر',
                      style: appTextTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),

                    if (errorText != null) ...[
                      Text(
                        errorText!,
                        style: TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                    ],

                    CustomInput(
                      controller: nameController,
                      labelText: 'نام',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'نام را وارد کنید';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomInput(
                      controller: familyController,
                      labelText: 'نام خانوادگی',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'نام خانوادگی را وارد کنید';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomInput(
                      controller: usernameController,
                      labelText: 'نام کاربری',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'نام کاربری را وارد کنید';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomInput(
                      controller: ageController,
                      labelText: 'سن',
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'سن را وارد کنید';
                        }
                        final age = int.tryParse(val);
                        if (age == null || age <= 0) {
                          return 'سن باید عددی مثبت باشد';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomDropdownInput<String>(
                      labelText: 'جنسیت',
                      initialValue: selectedGender,
                      validator:
                          (val) =>
                              (val == null || val.isEmpty)
                                  ? 'لطفاً جنسیت را انتخاب کنید'
                                  : null,
                      items:
                          genderMapFaToEn.keys
                              .map(
                                (genderFa) => DropdownMenuItem(
                                  value: genderFa,
                                  child: Text(genderFa),
                                ),
                              )
                              .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedGender = val;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    isLoading
                        ? const CircularProgressIndicator()
                        : CustomButton(
                          text: 'ذخیره',
                          onPressed: () async {
                            setState(() {
                              errorText = null;
                            });

                            if (!formKey.currentState!.validate()) {
                              // اعتبارسنجی فرم انجام نشد
                              return;
                            }

                            setState(() {
                              isLoading = true;
                            });

                            try {
                              final updateData = {
                                'name': nameController.text.trim(),
                                'family': familyController.text.trim(),
                                'username': usernameController.text.trim(),
                                'age': int.parse(ageController.text.trim()),
                                'gender':
                                    genderMapFaToEn[selectedGender!] ?? 'male',
                              };

                              await AuthApiService().updateMe(updateData);

                              setState(() {
                                isLoading = false;
                              });

                              Navigator.pop(context);

                              showCustomSnackBar(
                                context: context,
                                message: 'اطلاعات با موفقیت ذخیره شد',
                              );
                            } catch (e) {
                              setState(() {
                                errorText =
                                    e
                                        .toString()
                                        .replaceAll('Exception:', '')
                                        .trim();
                                isLoading = false;
                              });
                            }
                          },
                        ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showCustomBottomModal(
      context: context,
      child: Column(
        children: [
          Text('آیا مطمئن هستید؟', style: appTextTheme.titleMedium),
          const SizedBox(height: 16),
          Text(
            'آیا می‌خواهید از حساب کاربری خارج شوید؟',
            style: appTextTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'خروج',
                  onPressed: () {
                    Navigator.pop(context);
                    _logout();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'انصراف',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _logout() {
    PublicApiService().logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text('منو کاربری', style: appTextTheme.titleMedium),
        ),
        centerTitle: true,
        toolbarHeight: 72,

        leading: Padding(
          padding: const EdgeInsets.only(top: 24, right: 20),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 24),
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(width: 1, color: AppColors.primary),
            ),
            child: ListTile(
              title: const Text('ویرایش مشخصات'),
              leading: const Icon(Icons.person),
              trailing: const Icon(Iconsax.arrow_left_2, size: 20),
              onTap: _showEditUserModal,
            ),
          ),

          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(width: 1, color: AppColors.primary),
            ),
            child: ListTile(
              title: const Text('تغییر رمز عبور'),
              leading: const Icon(Icons.lock),
              trailing: const Icon(Iconsax.arrow_left_2, size: 20),
              onTap: _showChangePasswordModal,
            ),
          ),

          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(width: 1, color: AppColors.primary),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.brightness_6),
                    title: Text('حالت تم'),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ChoiceChip(
                        label: const Text('سیستم'),
                        selected: _themeMode == ThemeMode.system,
                        onSelected: (_) => _saveTheme(ThemeMode.system),
                      ),
                      ChoiceChip(
                        label: const Text('روشن'),
                        selected: _themeMode == ThemeMode.light,
                        onSelected: (_) => _saveTheme(ThemeMode.light),
                      ),
                      ChoiceChip(
                        label: const Text('تاریک'),
                        selected: _themeMode == ThemeMode.dark,
                        onSelected: (_) => _saveTheme(ThemeMode.dark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(width: 1, color: AppColors.primary),
            ),
            child: ListTile(
              title: const Text('مشاهده اطلاعیه‌ها'),
              leading: const Icon(Icons.announcement),
              trailing: const Icon(Iconsax.arrow_left_2, size: 20),
              onTap: _navigateToAnnouncementsPage,
            ),
          ),

          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(width: 1, color: AppColors.primary),
            ),
            child: ListTile(
              title: const Text('امتیازدهی به برنامه'),
              leading: const Icon(Icons.star),
              trailing: const Icon(Iconsax.arrow_left_2, size: 20),
              onTap: _showRatingModal,
            ),
          ),

          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(width: 1, color: AppColors.primary),
            ),
            child: ListTile(
              title: const Text('ارتباط با ما'),
              leading: const Icon(Icons.support_agent),
              trailing: const Icon(Iconsax.arrow_left_2, size: 20),
              onTap: _showContactUsModal,
            ),
          ),

          const SizedBox(height: 16),

          CustomButton(
            text: 'خروج از حساب کاربری',
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
    );
  }
}
