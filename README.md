# 📱 QR Scanner App

تطبيق **QR Scanner** مبني باستخدام Flutter، يوفّر تجربة سريعة وسهلة لمسح أكواد QR وإدارة الإعدادات الخاصة بالمستخدم.  
التطبيق مصمّم بواجهة بسيطة وسريعة، ويحتوي على إعدادات متقدمة وتجربة استخدام انسيابية.

---

## 🚀 المميزات

- 🔍 **مسح QR Codes بسرعة عالية**
- ⚙️ **شاشة إعدادات كاملة**
- 🌐 **التعامل مع APIs باستخدام Dio**
- 💾 **تخزين محلي باستخدام AppStorage**
- 🎨 **تصميم أنيق بخط Tajwal**
- 🧩 **تنظيم معماري واضح وسهل التوسّع**

---

## 🏗️ **التقنيات المستخدمة**

- **Flutter** (Dart)
- **Dio HTTP Client**
- **Local Storage**
- **Custom Navigation Router**
- **AI Paddle OCR**

---

## 📂 **هيكلة المشروع**

```plaintext
lib/
 ├── core/
 │    ├── appStorage/
 │    ├── dioHelper/
 │    └── router/
 ├── features/
 │    └── settings/
 ├── constant.dart
 └── main.dart
