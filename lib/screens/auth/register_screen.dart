import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;
  final int _totalPages = 5;
  bool _isLoading = false;

  // Veri tutucular
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Klavyeden "İleri" tuşuna basınca soyada geçmek için.
  final FocusNode _lastNameFocusNode = FocusNode();

  DateTime? _selectedDate;
  String _selectedGender = '';
  int _selectedGrade = 1;

  // Cumhuriyet Üniversitesi bölümleri
  final List<String> _cuDepartments = [
    'Bilgisayar Mühendisliği',
    'Diş Hekimliği',
    'Ebelik',
    'Eczacılık',
    'Elektrik-Elektronik Mühendisliği',
    'Gastronomi ve Mutfak Sanatları',
    'Hemşirelik',
    'Hukuk',
    'İktisat',
    'İlahiyat',
    'İngiliz Dili ve Edebiyatı',
    'İnşaat Mühendisliği',
    'İşletme',
    'Makine Mühendisliği',
    'Mimarlık',
    'Okul Öncesi Öğretmenliği',
    'Radyo, Televizyon ve Sinema',
    'Sınıf Öğretmenliği',
    'Tarih',
    'Tıp',
    'Veterinerlik',
    'Yönetim Bilişim Sistemleri (YBS)',
  ];

  @override
  void dispose() {
    _lastNameFocusNode.dispose();
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _departmentController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Yaş hesaplayıcı
  String get _calculatedAge {
    if (_selectedDate == null) return '';

    final today = DateTime.now();
    int age = today.year - _selectedDate!.year;

    if (today.month < _selectedDate!.month ||
        (today.month == _selectedDate!.month &&
            today.day < _selectedDate!.day)) {
      age--;
    }

    return '$age yaşında';
  }

  // Ay ismini Türkçeye çevirir.
  String _getTurkishMonth(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    return months[month - 1];
  }

  void _nextPage() {
    if (_currentPage == 0 &&
        (_firstNameController.text.trim().isEmpty ||
            _lastNameController.text.trim().isEmpty)) {
      _showError('Lütfen adını ve soyadını eksiksiz gir.');
      return;
    }

    if (_currentPage == 1 && _selectedDate == null) {
      _showError('Lütfen doğum tarihini seç.');
      return;
    }

    if (_currentPage == 2 && _selectedGender.isEmpty) {
      _showError('Lütfen cinsiyetini belirt.');
      return;
    }

    if (_currentPage == 3 &&
        _departmentController.text.trim().isEmpty) {
      _showError('Lütfen bölümünü seç veya yaz.');
      return;
    }

    if (_currentPage == 4 &&
        (_emailController.text.trim().isEmpty ||
            _passwordController.text.length < 6)) {
      _showError(
        'Geçerli bir kullanıcı adı ve en az 6 haneli şifre girmelisin.',
      );
      return;
    }

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _registerUser();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Kayıt işlemi ve e-posta doğrulaması
  Future<void> _registerUser() async {
    setState(() => _isLoading = true);

    try {
      final inputPrefix =
      _emailController.text.trim().split('@')[0];

      final fullEmail = '$inputPrefix@cumhuriyet.edu.tr';

      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

      // Firebase hesabını oluştur.
      final userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: fullEmail,
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-created',
          message: 'Kullanıcı hesabı oluşturulamadı.',
        );
      }

      // Doğrulama e-postasını gönder.
      await user.sendEmailVerification();

      // Kullanıcı bilgilerini Firestore'a kaydet.
      final newUser = UserModel(
        uid: user.uid,
        fullName: fullName,
        email: fullEmail,
        department: _departmentController.text.trim(),
        grade: _selectedGrade,
        gender: _selectedGender,
        birthDate: _selectedDate,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(newUser.uid)
          .set(newUser.toMap());

      if (!mounted) return;

      // Ana ekrana değil, doğrulama ekranına git.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const VerifyEmailScreen(),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showError(
          e.message ?? 'Kayıt olurken bir hata oluştu.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Kayıt sırasında bir hata oluştu: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 10.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                    ),
                    onPressed: _previousPage,
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (_currentPage + 1) / _totalPages,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade300,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(
                          primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (int page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildNameStep(isDark),
                  _buildDateStep(isDark, primaryColor),
                  _buildGenderStep(isDark, primaryColor),
                  _buildUniversityStep(isDark, primaryColor),
                  _buildEmailPasswordStep(isDark, primaryColor),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextPage,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : Text(
                  _currentPage == _totalPages - 1
                      ? 'Kaydı Tamamla'
                      : 'Devam Et',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. ADIM: Ad Soyad
  Widget _buildNameStep(bool isDark) {
    return _buildStepContainer(
      title: 'Seni Tanıyalım 👋',
      subtitle: 'Öncelikle, adın ve soyadın nedir?',
      child: Column(
        children: [
          TextField(
            controller: _firstNameController,
            style: const TextStyle(fontSize: 16),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              FocusScope.of(context)
                  .requestFocus(_lastNameFocusNode);
            },
            decoration: _modernInputDecoration('Adın', isDark),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lastNameController,
            focusNode: _lastNameFocusNode,
            style: const TextStyle(fontSize: 16),
            textInputAction: TextInputAction.done,
            decoration: _modernInputDecoration(
              'Soyadın',
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  // 2. ADIM: Doğum Tarihi
  Widget _buildDateStep(
      bool isDark,
      Color primaryColor,
      ) {
    return _buildStepContainer(
      title: 'Doğum Tarihin 🎂',
      subtitle:
      'Yaşını hesaplamamız ve doğru etkinlikleri önermemiz için gerekli.',
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor:
            isDark ? const Color(0xFF2A2324) : Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            builder: (BuildContext builder) {
              return SizedBox(
                height: 300,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context),
                            child: Text(
                              'Bitti',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Localizations.override(
                        context: context,
                        locale: const Locale('tr', 'TR'),
                        child: CupertinoTheme(
                          data: CupertinoThemeData(
                            brightness: isDark
                                ? Brightness.dark
                                : Brightness.light,
                          ),
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.date,
                            initialDateTime:
                            _selectedDate ?? DateTime(2004),
                            minimumDate: DateTime(1950),
                            maximumDate: DateTime.now(),
                            onDateTimeChanged:
                                (DateTime newDate) {
                              setState(() {
                                _selectedDate = newDate;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2A2324)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Doğum Tarihi',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedDate == null
                    ? 'Gün / Ay / Yıl Seçin'
                    : '${_selectedDate!.day.toString().padLeft(2, '0')} '
                    '${_getTurkishMonth(_selectedDate!.month)} '
                    '${_selectedDate!.year}  ($_calculatedAge)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _selectedDate == null
                      ? Colors.grey
                      : (isDark ? Colors.white : Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. ADIM: Cinsiyet
  Widget _buildGenderStep(
      bool isDark,
      Color primaryColor,
      ) {
    final genders = [
      'Erkek',
      'Kadın',
      'Belirtmek İstemiyorum',
    ];

    return _buildStepContainer(
      title: 'Cinsiyetin 👤',
      subtitle: 'Profilinde nasıl görünmek istersin?',
      child: Column(
        children: genders.map((gender) {
          final isSelected = _selectedGender == gender;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedGender = gender;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withOpacity(0.1)
                    : (isDark
                    ? const Color(0xFF2A2324)
                    : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    gender,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: primaryColor,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 4. ADIM: Üniversite
  Widget _buildUniversityStep(
      bool isDark,
      Color primaryColor,
      ) {
    return _buildStepContainer(
      title: 'Eğitim Bilgilerin 🎓',
      subtitle:
      'Cumhuriyet Üniversitesindeki bölümünü ara ve seç.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Autocomplete<String>(
            optionsBuilder:
                (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }

              return _cuDepartments.where((String option) {
                return option.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                );
              });
            },
            onSelected: (String selection) {
              _departmentController.text = selection;
            },
            fieldViewBuilder: (
                context,
                controller,
                focusNode,
                onEditingComplete,
                ) {
              controller.addListener(() {
                _departmentController.text = controller.text;
              });

              return TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(fontSize: 16),
                decoration: _modernInputDecoration(
                  'Bölüm Ara (Örn: Bilgisayar)',
                  isDark,
                ),
              );
            },
            optionsViewBuilder: (
                context,
                onSelected,
                options,
                ) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  color: isDark
                      ? const Color(0xFF2A2324)
                      : Colors.white,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                      maxWidth: 300,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (
                          BuildContext context,
                          int index,
                          ) {
                        final option = options.elementAt(index);

                        return ListTile(
                          title: Text(
                            option,
                            style: const TextStyle(fontSize: 15),
                          ),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          const Text(
            'Kaçıncı Sınıfsın?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [1, 2, 3, 4, 5, 6].map((grade) {
              final isSelected = _selectedGrade == grade;

              return ChoiceChip(
                label: Text(
                  '$grade. Sınıf',
                  style: TextStyle(
                    fontSize: 15,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                        ? Colors.white
                        : Colors.black),
                  ),
                ),
                selected: isSelected,
                selectedColor: primaryColor,
                backgroundColor: isDark
                    ? const Color(0xFF2A2324)
                    : Colors.grey.shade200,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedGrade = grade;
                    });
                  }
                },
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 5. ADIM: E-posta ve Şifre
  Widget _buildEmailPasswordStep(
      bool isDark,
      Color primaryColor,
      ) {
    return _buildStepContainer(
      title: 'Son Adım! 🚀',
      subtitle:
      'Sadece okul öğrenci numaranı veya kullanıcı adını gir, uzantıyı biz hallederiz.',
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.text,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Öğrenci No / Kullanıcı Adı',
              suffixText: '@cumhuriyet.edu.tr',
              suffixStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
                fontSize: 14,
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF2A2324)
                  : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(fontSize: 16),
            decoration: _modernInputDecoration(
              'Şifre (En az 6 hane)',
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 10.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          child,
        ],
      ),
    );
  }

  InputDecoration _modernInputDecoration(
      String hint,
      bool isDark,
      ) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: isDark
          ? const Color(0xFF2A2324)
          : Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
      ),
    );
  }
}