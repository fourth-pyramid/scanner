import 'package:flutter/material.dart';
import 'package:qrscanner/constant.dart';

class AppDisabledView extends StatelessWidget {
  const AppDisabledView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorPrimary.withAlpha((0.8 * 255).toInt()), colorPrimary],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.15 * 255).toInt()),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'التطبيق متوقف حالياً',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajwal',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'يرجى التواصل مع المطور لتفعيل الخدمة أو للحصول على المزيد من المعلومات.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontFamily: 'Tajwal',
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                // ElevatedButton(
                //   onPressed: () {
                //     // Logic to contact developer can be added here
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.white,
                //     foregroundColor: colorPrimary,
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 40,
                //       vertical: 15,
                //     ),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(30),
                //     ),
                //     elevation: 5,
                //   ),
                //   child: const Text(
                //     'تواصل مع المطور',
                //     style: TextStyle(
                //       fontSize: 18,
                //       fontWeight: FontWeight.bold,
                //       fontFamily: 'Tajwal',
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
