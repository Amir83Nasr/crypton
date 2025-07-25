import 'package:crypton_frontend/theme.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CustomDropdownInput<T> extends FormField<T> {
  final List<DropdownMenuItem<T>> items;
  final String labelText;

  CustomDropdownInput({
    super.key,
    T? initialValue, // مقدار اولیه nullable
    required this.items,
    required this.labelText,
    super.validator,
    required void Function(T?) onChanged,
  }) : super(
         builder: (FormFieldState<T> state) {
           return _CustomDropdownWidget<T>(
             state: state,
             items: items,
             labelText: labelText,
             onChanged: onChanged,
           );
         },
       );
}

class _CustomDropdownWidget<T> extends StatelessWidget {
  final FormFieldState<T> state;
  final List<DropdownMenuItem<T>> items;
  final String labelText;
  final void Function(T?) onChanged;

  const _CustomDropdownWidget({
    super.key,
    required this.state,
    required this.items,
    required this.labelText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8);

    return InputDecorator(
      decoration: InputDecoration(
        filled: true,
        labelText: labelText,
        labelStyle: appTextTheme.labelLarge,
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: AppColors.primary),
        ),
        errorText: state.errorText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: const Icon(Iconsax.arrow_down_1, size: 24),
      ),
      isEmpty: state.value == null,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: state.value,
          isDense: true,
          icon: const SizedBox.shrink(),
          items: items,
          onChanged: (newValue) {
            state.didChange(newValue);
            onChanged(newValue);
          },
          dropdownColor: Colors.white,
          itemHeight: 48,
          borderRadius: borderRadius,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
