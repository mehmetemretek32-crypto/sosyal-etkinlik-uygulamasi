import 'package:flutter/material.dart';

class CustomLoading extends StatefulWidget {
  const CustomLoading({super.key});

  @override
  State<CustomLoading> createState() => _CustomLoadingState();
}

class _CustomLoadingState extends State<CustomLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Animasyon 800 milisaniyede bir kendini tekrar edip geri dönecek (Nefes alma efekti)
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this)..repeat(reverse: true);
    // Logonun boyutu %80'den %110'a kadar yumuşakça büyüyüp küçülecek
    _animation = Tween<double>(begin: 0.8, end: 1.1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose(); // Bellek sızıntısını önlemek için animasyonu kapatıyoruz
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _animation,
        child: Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset('assets/logo.jpg', fit: BoxFit.cover),
        ),
      ),
    );
  }
}