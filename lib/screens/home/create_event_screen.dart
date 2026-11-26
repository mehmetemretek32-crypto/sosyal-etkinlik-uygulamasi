import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'map_picker_screen.dart';

class CreateEventScreen extends StatefulWidget {
  final UserModel currentUser;
  final VoidCallback onSuccess;

  const CreateEventScreen({super.key, required this.currentUser, required this.onSuccess});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color _primaryColor = const Color(0xFF6A1221); // İMZA BORDO
  bool _isLoading = false;

  final TextEditingController _titleController = TextEditingController();

  String _selectedCategory = 'Eğlence';
  final List<String> _categories = ['Eğlence', 'Spor', 'Eğitim', 'Oyun', 'Sohbet', 'Yemek', 'Kültür', 'Müzik'];

  final TextEditingController _tagController = TextEditingController();
  final List<String> _tags = [];

  bool _isOnline = false;
  final TextEditingController _locationController = TextEditingController();
  LatLng? _selectedLatLng;
  final TextEditingController _platformController = TextEditingController();
  final TextEditingController _platformLinkController = TextEditingController();

  DateTime? _startDate; TimeOfDay? _startTime;
  DateTime? _endDate; TimeOfDay? _endTime;

  bool _hasCapacityLimit = true;
  final TextEditingController _capacityController = TextEditingController(text: '10');
  bool _requiresApproval = true;

  // TÜM KATEGORİLERE ÖZEL YÜKSEK KALİTELİ GALERİ (UNSPLASH)
  String _selectedCover = 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=600&q=80';

  final Map<String, List<String>> _categoryCovers = {
    'Eğlence': [
      'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=600&q=80',
      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&q=80',
      'https://images.unsplash.com/photo-1549451371-64aa98a6f660?w=600&q=80',
      'https://images.unsplash.com/photo-1533174000255-598d944038fe?w=600&q=80',
    ],
    'Spor': [
      'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=600&q=80',
      'https://images.unsplash.com/photo-1526566762798-8fac9c07aa98?w=600&q=80',
      'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=600&q=80',
      'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=600&q=80',
    ],
    'Oyun': [
      'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=600&q=80',
      'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=600&q=80',
      'https://images.unsplash.com/photo-1552820728-8b83bb6b773f?w=600&q=80',
      'https://images.unsplash.com/photo-1534423861386-85a16f5d13fd?w=600&q=80',
    ],
    'Sohbet': [
      'https://images.unsplash.com/photo-1528605248644-14dd04022da1?w=600&q=80',
      'https://images.unsplash.com/photo-1517486808906-6ca8b3f04846?w=600&q=80',
      'https://images.unsplash.com/photo-1577563908411-5077b6dc7624?w=600&q=80',
      'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=600&q=80',
    ],
    'Yemek': [
      'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=600&q=80',
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&q=80',
      'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&q=80',
      'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=600&q=80',
    ],
    'Eğitim': [
      'https://images.unsplash.com/photo-1524178232363-1fb2b075b655?w=600&q=80',
      'https://images.unsplash.com/photo-1513258496099-48168024aec0?w=600&q=80',
      'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=600&q=80',
      'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=600&q=80',
    ],
    'Kültür': [
      'https://images.unsplash.com/photo-1514539079130-25950c84af65?w=600&q=80',
      'https://images.unsplash.com/photo-1533050487297-09b45013190a?w=600&q=80',
      'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?w=600&q=80',
      'https://images.unsplash.com/photo-1526481280693-3bfa7568e0f3?w=600&q=80',
    ],
    'Müzik': [
      'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=600&q=80',
      'https://images.unsplash.com/photo-1511192336575-5a79af67a629?w=600&q=80',
      'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&q=80',
      'https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=600&q=80',
    ],
  };

  @override
  void dispose() {
    _titleController.dispose(); _tagController.dispose();
    _locationController.dispose(); _platformController.dispose();
    _platformLinkController.dispose(); _capacityController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) setState(() { _tags.add(tag); _tagController.clear(); });
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: _primaryColor)), child: child!),
    );
    if (picked != null) setState(() { isStart ? _startDate = picked : _endDate = picked; });
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context, initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: _primaryColor)), child: child!),
    );
    if (picked != null) setState(() { isStart ? _startTime = picked : _endTime = picked; });
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _startTime == null || _endDate == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tarih/saat eksik.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day, _startTime!.hour, _startTime!.minute);
      final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, _endTime!.hour, _endTime!.minute);

      await FirebaseFirestore.instance.collection('events').add({
        'hostId': widget.currentUser.uid,
        'title': _titleController.text.trim(),
        'category': _selectedCategory,
        'coverImage': _selectedCover,
        'tags': _tags,
        'isOnline': _isOnline,
        'locationName': _isOnline ? _platformController.text.trim() : _locationController.text.trim(),
        'platformLink': _isOnline ? _platformLinkController.text.trim() : '',
        'latitude': _isOnline ? null : _selectedLatLng?.latitude,
        'longitude': _isOnline ? null : _selectedLatLng?.longitude,
        'eventDate': Timestamp.fromDate(start),
        'endDate': Timestamp.fromDate(end),
        'maxCapacity': _hasCapacityLimit ? int.tryParse(_capacityController.text) ?? 10 : 999,
        'requiresApproval': _requiresApproval,
        'currentCount': 1, 'approvedUserIds': [widget.currentUser.uid], 'pendingUserIds': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oluşturuldu!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.black)); widget.onSuccess(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _customInputDeco(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true, fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
    );
  }

  // YENİDEN YAZILAN ÇÖKMESİZ ADIM FONKSİYONU (STACK KULLANILDI)
  Widget _buildStep(int stepNum, String title, Widget content, {bool isLast = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // ARKADAKİ ÇİZGİ
        if (!isLast)
          Positioned(
            top: 28,
            bottom: 0,
            left: 13, // Yuvarlağın ortasına hiza
            child: Container(width: 2, color: _primaryColor.withOpacity(0.3)),
          ),

        // ÖNDEKİ İÇERİK
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: _primaryColor, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(stepNum.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 40 : 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 16),
                    content,
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    // Kategoriye ait resimleri güvenle çek
    final currentCategoryImages = _categoryCovers[_selectedCategory] ?? _categoryCovers['Eğlence']!;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text('Etkinlik Oluştur', style: TextStyle(fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
        centerTitle: false, elevation: 0, backgroundColor: Colors.transparent,
      ),
      body: _isLoading ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildStep(1, 'Etkinlik Detayları', Column(
                children: [
                  TextFormField(controller: _titleController, decoration: _customInputDeco('Etkinlik Başlığı', isDark), style: TextStyle(color: textColor, fontWeight: FontWeight.w600), validator: (val) => val!.isEmpty ? 'Gerekli' : null),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: _customInputDeco('Kategori', isDark),
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategory = val!;
                        // Kategori değiştiğinde ilk resmi seç
                        _selectedCover = _categoryCovers[_selectedCategory]?.first ?? _categoryCovers['Eğlence']!.first;
                      });
                    },
                  ),
                ],
              )),

              _buildStep(2, 'Kapak Fotoğrafı Seçin', Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_selectedCategory temalı fotoğraflar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: currentCategoryImages.length,
                    itemBuilder: (context, index) {
                      final imgUrl = currentCategoryImages[index];
                      final isSelected = _selectedCover == imgUrl;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedCover = imgUrl),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? _primaryColor : Colors.transparent, width: 3),
                            image: DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover),
                            boxShadow: isSelected ? [BoxShadow(color: _primaryColor.withOpacity(0.4), blurRadius: 8)] : null,
                          ),
                          child: isSelected
                              ? Container(
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(13)),
                            child: const Center(child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 36)),
                          )
                              : null,
                        ),
                      );
                    },
                  ),
                ],
              )),

              _buildStep(3, 'Etiketler', Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _tagController, style: TextStyle(color: textColor, fontWeight: FontWeight.w600), decoration: _customInputDeco('Ör: dans, yemek..', isDark), onFieldSubmitted: (_) => _addTag())),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _addTag,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: const Text('Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  if (_tags.isNotEmpty) Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Wrap(spacing: 8, runSpacing: 8, children: _tags.map((t) => Chip(label: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black)), backgroundColor: Colors.grey.shade200, side: BorderSide.none, onDeleted: () => setState(() => _tags.remove(t)))).toList()),
                  )
                ],
              )),

              _buildStep(4, 'Konum', Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Expanded(child: GestureDetector(onTap: () => setState(() => _isOnline = false), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: !_isOnline ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12), boxShadow: !_isOnline ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null), alignment: Alignment.center, child: Text('Mekan', style: TextStyle(color: !_isOnline ? Colors.black : Colors.grey, fontWeight: FontWeight.bold))))),
                        Expanded(child: GestureDetector(onTap: () => setState(() => _isOnline = true), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _isOnline ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12), boxShadow: _isOnline ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null), alignment: Alignment.center, child: Text('Online', style: TextStyle(color: _isOnline ? Colors.black : Colors.grey, fontWeight: FontWeight.bold))))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_isOnline) TextFormField(
                    controller: _locationController, style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                    decoration: _customInputDeco('Mekan Adı (Ör: ÖYM)', isDark).copyWith(
                        prefixIcon: Icon(Icons.location_on, color: Colors.grey.shade400),
                        suffixIcon: IconButton(icon: Icon(Icons.map_rounded, color: _selectedLatLng != null ? Colors.green : Colors.black87), onPressed: () async {
                          final LatLng? loc = await Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPickerScreen()));
                          if (loc != null) setState(() => _selectedLatLng = loc);
                        })
                    ), validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                  ) else ...[
                    TextFormField(controller: _platformController, style: TextStyle(color: textColor, fontWeight: FontWeight.w600), decoration: _customInputDeco('Platform (Ör: Zoom)', isDark).copyWith(prefixIcon: Icon(Icons.computer, color: Colors.grey.shade400)), validator: (v) => v!.isEmpty ? 'Gerekli' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _platformLinkController, style: TextStyle(color: textColor, fontWeight: FontWeight.w600), decoration: _customInputDeco('Link (İsteğe Bağlı)', isDark).copyWith(prefixIcon: Icon(Icons.link, color: Colors.grey.shade400))),
                  ]
                ],
              )),

              _buildStep(5, 'Takvim', Column(
                children: [
                  Row(children: [
                    Expanded(child: InkWell(onTap: () => _pickDate(true), child: Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Text(_startDate == null ? 'Başlama Tarihi' : DateFormat('dd MMM', 'tr').format(_startDate!), style: TextStyle(fontWeight: FontWeight.w600, color: _startDate == null ? Colors.grey.shade400 : textColor))))),
                    const SizedBox(width: 12),
                    Expanded(child: InkWell(onTap: () => _pickTime(true), child: Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Text(_startTime == null ? 'Saat' : _startTime!.format(context), style: TextStyle(fontWeight: FontWeight.w600, color: _startTime == null ? Colors.grey.shade400 : textColor))))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: InkWell(onTap: () => _pickDate(false), child: Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Text(_endDate == null ? 'Bitiş Tarihi' : DateFormat('dd MMM', 'tr').format(_endDate!), style: TextStyle(fontWeight: FontWeight.w600, color: _endDate == null ? Colors.grey.shade400 : textColor))))),
                    const SizedBox(width: 12),
                    Expanded(child: InkWell(onTap: () => _pickTime(false), child: Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Text(_endTime == null ? 'Saat' : _endTime!.format(context), style: TextStyle(fontWeight: FontWeight.w600, color: _endTime == null ? Colors.grey.shade400 : textColor))))),
                  ]),
                ],
              )),

              _buildStep(6, 'Ayarlar', Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Kapasite Limiti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Switch(value: _hasCapacityLimit, activeColor: _primaryColor, onChanged: (v) => setState(() => _hasCapacityLimit = v))]),
                  if (_hasCapacityLimit) Padding(padding: const EdgeInsets.only(top: 8), child: TextFormField(controller: _capacityController, style: TextStyle(color: textColor, fontWeight: FontWeight.w600), keyboardType: TextInputType.number, decoration: _customInputDeco('Kişi Sayısı', isDark), validator: (v) => v!.isEmpty ? 'Girin' : null)),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Katılım Onayı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Switch(value: _requiresApproval, activeColor: _primaryColor, onChanged: (v) => setState(() => _requiresApproval = v))]),
                ],
              ), isLast: true),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('KAYDET', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}