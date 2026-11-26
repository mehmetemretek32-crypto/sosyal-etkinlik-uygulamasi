import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import 'main_nav_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel currentUser;

  const EditProfileScreen({super.key, required this.currentUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _departmentController;
  late TextEditingController _bioController;
  late TextEditingController _interestsController;
  late int _selectedGrade;

  late String _selectedGender;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.fullName);
    _departmentController = TextEditingController(text: widget.currentUser.department);
    _bioController = TextEditingController(text: widget.currentUser.bio);
    _interestsController = TextEditingController(text: widget.currentUser.interests.join(', '));
    _selectedGrade = widget.currentUser.grade;
    _selectedGender = widget.currentUser.gender;
    _selectedDate = widget.currentUser.birthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _bioController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  String _getTurkishMonth(int month) {
    const months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return months[month - 1];
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen doğum tarihini seç.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> updatedInterests = _interestsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance.collection('users').doc(widget.currentUser.uid).update({
        'fullName': _nameController.text.trim(),
        'department': _departmentController.text.trim(),
        'grade': _selectedGrade,
        'bio': _bioController.text.trim(),
        'interests': updatedInterests,
        'gender': _selectedGender,
        'birthDate': Timestamp.fromDate(_selectedDate!),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilin başarıyla güncellendi! ✅'), backgroundColor: Colors.green),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
            (route) => false,
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Güncelleme sırasında bir hata oluştu.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              const Text('Ad Soyad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: _modernInputDecoration('Adın ve Soyadın', isDark),
                validator: (val) => val == null || val.trim().isEmpty ? 'Ad soyad boş bırakılamaz.' : null,
              ),
              const SizedBox(height: 24),

              // DOĞUM TARİHİ KISMI (Optimizasyon Yapıldı)
              const Text('Doğum Tarihi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  // Performans için geçici değişken kullanıyoruz
                  DateTime tempDate = _selectedDate ?? DateTime(2004);

                  showModalBottomSheet(
                    context: context,
                    backgroundColor: isDark ? const Color(0xFF2A2324) : Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (BuildContext builder) {
                      return SizedBox(
                        height: 300,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      // Sadece "Bitti" tuşuna basıldığında ekranı yenile
                                      setState(() => _selectedDate = tempDate);
                                      Navigator.pop(context);
                                    },
                                    child: Text('Bitti', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                                  )
                                ],
                              ),
                            ),
                            Expanded(
                              child: Localizations.override(
                                context: context,
                                locale: const Locale('tr', 'TR'),
                                child: CupertinoTheme(
                                  data: CupertinoThemeData(
                                    brightness: isDark ? Brightness.dark : Brightness.light,
                                  ),
                                  child: CupertinoDatePicker(
                                    mode: CupertinoDatePickerMode.date,
                                    initialDateTime: tempDate,
                                    minimumDate: DateTime(1950),
                                    maximumDate: DateTime.now(),
                                    onDateTimeChanged: (DateTime newDate) {
                                      // setState YENİDEN ÇİZİMİNİ İPTAL ETTİK (Kasmayı engeller)
                                      tempDate = newDate;
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2324) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null
                            ? 'Doğum Tarihi Seçin'
                            : '${_selectedDate!.day.toString().padLeft(2, '0')} ${_getTurkishMonth(_selectedDate!.month)} ${_selectedDate!.year}',
                        style: TextStyle(
                            fontSize: 16,
                            color: _selectedDate == null ? Colors.grey : (isDark ? Colors.white : Colors.black)
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // CİNSİYET KISMI
              const Text('Cinsiyet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['Erkek', 'Kadın', 'Belirtmek İstemiyorum'].map((gender) {
                  bool isSelected = _selectedGender == gender;
                  return ChoiceChip(
                    label: Text(gender, style: TextStyle(fontSize: 15, color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black))),
                    selected: isSelected,
                    selectedColor: primaryColor,
                    backgroundColor: isDark ? const Color(0xFF2A2324) : Colors.grey.shade200,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedGender = gender);
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              const Text('Bölüm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _departmentController,
                decoration: _modernInputDecoration('Okuduğun Bölüm', isDark),
                validator: (val) => val == null || val.trim().isEmpty ? 'Bölüm boş bırakılamaz.' : null,
              ),
              const SizedBox(height: 24),

              const Text('Sınıf', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [1, 2, 3, 4, 5, 6].map((grade) {
                  bool isSelected = _selectedGrade == grade;
                  return ChoiceChip(
                    label: Text('$grade. Sınıf', style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black))),
                    selected: isSelected,
                    selectedColor: primaryColor,
                    backgroundColor: isDark ? const Color(0xFF2A2324) : Colors.grey.shade200,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedGrade = grade);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              const Text('Hakkımda (Biyografi)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: _modernInputDecoration('Kendinden kısaca bahset...', isDark),
              ),
              const SizedBox(height: 24),

              const Text('İlgi Alanları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _interestsController,
                decoration: _modernInputDecoration('Müzik, Spor, Yazılım (Virgülle ayır)', isDark).copyWith(
                  hintStyle: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Değişiklikleri Kaydet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _modernInputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: isDark ? const Color(0xFF2A2324) : Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
    );
  }
}