String convertToPersianNumber(dynamic input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  final inputStr = input.toString();

  return inputStr
      .split('')
      .map(
        (char) =>
            english.contains(char) ? persian[english.indexOf(char)] : char,
      )
      .join('');
}
