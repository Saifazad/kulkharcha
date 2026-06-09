# KulKharcha 🤖💰

An AI-powered, automated expense tracker that intelligently parses banking SMS alerts to manage daily finances locally and securely.

---

## 🔒 Privacy-First Design
KulKharcha is built with a **100% offline-first** approach. Your financial data is extremely sensitive, which is why:
* **No Cloud Servers**: No transaction data or personal details ever leave your device.
* **No Internet Required**: The app runs completely offline.
* **Secure Local Database**: All records are saved locally using an encrypted-compatible SQLite database structure on your device.

---

## ✨ Features

* **Real-time SMS Auto-Tracking**: Instantly detects transactional debit SMS alerts from major Indian banks and extracts the exact amount spent.
* **Smart Auto-Categorization**: Automatically categorizes transactions into 8 comprehensive categories:
  * 🌾 **Kheti/Farming**
  * 🍔 **Food & Groceries**
  * 💡 **Bills & Recharges**
  * 🚗 **Fuel & Transport**
  * 🛍️ **Shopping**
  * 🏥 **Medical & Health**
  * 🏧 **Cash (ATM)**
  * ⚙️ **General**
* **Merchant Personalization**: Learn from user overrides. If you re-categorize a transaction (e.g., classifying a transfer to a local shop as "Food"), the app remembers the merchant name and maps future alerts automatically.
* **Location Geo-Tagging**: Integrates device GPS to tag transactions with human-readable location addresses so you remember *where* you spent your money.
* **KulkAI Smart Insights**: A local analysis engine that runs on your recent transactions to give friendly, conversational Hinglish suggestions (e.g., warning you about impulsive online orders or repeated small purchases).
* **Daily & Monthly Budget Limits**: Set personal limits and get visual warnings when you are close to exceeding them.

---

## 🛠️ Tech Stack & Packages

* **Frontend Framework**: [Flutter](https://flutter.dev/) (Dart)
* **Local Database**: [SQLite](https://pub.dev/packages/sqflite) (`sqflite`) for robust local structured storage.
* **Background Processing**: [Workmanager](https://pub.dev/packages/workmanager) for periodic background SMS syncing.
* **SMS Listeners**: 
  * `easy_sms_receiver` for real-time incoming alerts.
  * `flutter_sms_inbox` for periodic inbox parsing.
* **Location APIs**: `geolocator` & `geocoding` for fetching and reverse-geocoding coordinates.
* **State & Storage**: `shared_preferences` for light-weight configurations and budget targets.

---

## 🚀 Getting Started

### Prerequisites
Make sure you have the following installed on your machine:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.11.4 or higher recommended)
* Android Studio / Xcode (for mobile emulation)

### Setup Instructions

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Saifazad/kulkharcha.git
   cd kulkharcha
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the App**:
   * Connect an Android device with SMS capabilities (or use an emulator).
   * Execute:
     ```bash
     flutter run
     ```

---

## 📱 Permissions Required
For full automation features, the app requests:
* **SMS Read**: To parse bank transactions.
* **Location Access**: To tag transactions with merchant addresses.
* **Notification Access**: To send budget breaches and summaries.

---

## 📄 License
This project is proprietary/open-source. Feel free to use and customize for personal use.
