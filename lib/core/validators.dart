class AppValidators {
  // Sadece @ogr.cumhuriyet.edu.tr ve @cumhuriyet.edu.tr uzantılarını kabul eder
  static String? validateCampusEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta adresi boş bırakılamaz.';
    }

    final email = value.trim().toLowerCase();
    final isStudentEmail = email.endsWith('@ogr.cumhuriyet.edu.tr');
    final isAcademicEmail = email.endsWith('@cumhuriyet.edu.tr');

    if (!isStudentEmail && !isAcademicEmail) {
      return 'Sadece @ogr.cumhuriyet.edu.tr uzantılı öğrenci e-postası ile kayıt olabilirsiniz.';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır.';
    }
    return null;
  }
}