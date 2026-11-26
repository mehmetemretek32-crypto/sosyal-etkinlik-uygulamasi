import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // Başlangıç noktası: Sivas Cumhuriyet Üniversitesi (Ortalama Koordinatlar)
  LatLng _currentCenter = const LatLng(39.7088, 37.0245);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Haritadan Konum Seç', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                _currentCenter = position.center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dorduncu',
              ),
            ],
          ),

          // EKRANIN TAM ORTASINDAKİ SABİT PİN (Kullanıcı haritayı kaydırdıkça yerinde durur)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0), // Pin ucunu merkeze oturtmak için
              child: Icon(Icons.location_on, size: 50, color: primaryColor),
            ),
          ),

          // ONAYLAMA BUTONU
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                // Seçilen koordinatı (LatLng) bir önceki sayfaya döndür
                Navigator.pop(context, _currentCenter);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: const Text('Bu Konumu Seç', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}