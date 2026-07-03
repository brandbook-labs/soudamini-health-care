# Jivan App 🏥

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Status](https://img.shields.io/badge/Status-In%20Development-yellow?style=for-the-badge)

**Jivan** is a comprehensive healthcare mobile application built with Flutter. It connects patients with healthcare services including doctor consultations, lab tests, medicine delivery, and health resources.

---

## 📱 Features

### **Core Modules**
* **🩺 Doctor Consultation:** Browse top specialists, view profiles, and book appointments.
* **🧪 Lab Tests:** Schedule diagnostic tests with home collection options.
* **💊 Medicine Delivery:** Order medicines online with bill waiver offers.
* **📰 Health Feed:** Curated articles and health tips.

### **User Experience**
* **Quick Actions Grid:** Fast access to primary services with live status indicators.
* **Smart Profile:** Manage medical records, appointments, and app settings.
* **Dark/Light Mode:** Fully responsive theme support affecting all screens and widgets.
* **Secure Authentication:** Integrated `smart_auth` for OTP/Phone verification flows.

---

## 🛠️ Tech Stack

* **Framework:** [Flutter](https://flutter.dev/) (SDK >=3.0.0)
* **Language:** Dart
* **Icons:** `lucide_icons` for modern UI elements.
* **Sharing:** `share_plus` for inviting friends.
* **Build Tooling:** Gradle with Kotlin DSL (`.kts`).

---

## 📸 Screenshots

| Home Screen | Profile & Settings | Quick Actions |
|:---:|:---:|:---:|
| <img src="docs/screenshots/home.png" width="200" /> | <img src="docs/screenshots/profile.png" width="200" /> | <img src="docs/screenshots/actions.png" width="200" /> |

*(Note: Add your screenshots to a `docs/screenshots/` folder in your repo to display them here)*

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK installed.
* Android Studio / VS Code setup.
* Java/JDK 17 installed (required for Gradle).

### Installation

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/brandbook-labs/jivan-app.git](https://github.com/brandbook-labs/jivan-app.git)
    cd jivan-app
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run in Debug Mode:**
    ```bash
    flutter run
    ```

---

## 🔐 Build & Release (Android)

This project is configured for secure release builds using a private keystore.

### 1. Keystore Setup (First Time Only)
To build a release APK, you must have the `key.properties` file and the `upload-keystore.jks` file in the `android/` directory.

**⚠️ These files are ignored by Git for security.**

**If you have them backed up:**
1.  Place `upload-keystore.jks` into `android/app/`.
2.  Place `key.properties` into `android/`.

**`android/key.properties` format:**
```properties
storePassword=YOUR_SECRET_PASSWORD
keyPassword=YOUR_SECRET_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks