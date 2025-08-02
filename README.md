# Flutter Secure Chat Application Frontend

This repository contains the frontend source code for a modern, secure, cross-platform chat application built with Flutter. The application provides end-to-end encrypted messaging, real-time presence updates, and high-quality peer-to-peer video & audio calls.

![Chat App Mockup](https://via.placeholder.com/800x450.png?text=Your+App+Screenshot+Here)
*(Suggestion: Replace the placeholder link above with a screenshot of your app)*

---

## ✨ Features

- **Cross-Platform:** Single codebase for both Android and iOS using Flutter.
- **Secure Communication:**
    - **End-to-End Encryption (E2EE):** All text messages transfers are encrypted. The server has no ability to read message content.
    - **Secure Key Exchange:** Utilizes RSA for the secure exchange of symmetric AES keys for group chats.
- **Real-time Messaging:** Instant message delivery and status updates powered by Socket.io.
- **High-Quality Calls:** Peer-to-peer (P2P) video and audio calls built with WebRTC, ensuring low latency and privacy.
- **User Presence:** Real-time online/offline status indicators for contacts.
- **Modern Architecture:** Built following the **MVVM (Model-View-ViewModel)** pattern for a clean, scalable, and testable codebase.
- **State Management:** Uses the `Provider` package for efficient and simple state management.

---

## 🛠️ Tech Stack & Key Libraries

- **Framework:** [Flutter](https://flutter.dev/)
- **Programming Language:** [Dart](https://dart.dev/)
- **Architecture:** MVVM (Model-View-ViewModel)
- **State Management:** [Provider](https://pub.dev/packages/provider)
- **Networking:**
    - [Dio](https://pub.dev/packages/dio) for REST API communication.
    - [socket_io_client](https://pub.dev/packages/socket_io_client) for WebSocket communication.
- **Security & Encryption:**
    - [fast_rsa](https://pub.dev/packages/fast_rsa) for RSA asymmetric encryption (key exchange).
    - [encrypt](https://pub.dev/packages/encrypt) for AES symmetric encryption (message content).
- **Real-time Calls:** [flutter_webrtc](https://pub.dev/packages/flutter_webrtc)
- **Secure Storage:** [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) for storing auth tokens and private keys.
- **Dependency Injection:** [get_it](https://pub.dev/packages/get_it)

---

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.x or higher recommended)
- [Dart SDK](https://dart.dev/get-dart)
- An editor like [VS Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio)
- A running instance of the [backend server](https://github.com/your-username/your-backend-repo-link). *(<- IMPORTANT: Link to your backend repository here)*

### Installation & Setup

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/tammam-alsoleman/Chat_APP_FRONTEND.git
    cd Chat_APP_FRONTEND
    ```

2.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

3.  **Configure the environment:**
    - Open the file `lib/core/config.dart`.
    - Update the `baseUrl` for the `development` environment to point to your local backend server's IP address and port.
    ```dart
    case Environment.development:
      baseUrl = 'http://YOUR_LOCAL_IP_ADDRESS:5000';
      break;
    ```

4.  **Run the application:**
    ```sh
    flutter run
    ```

---

## 🏛️ Project Structure

The project follows a feature-first, layered architectural approach to maintain a clean and scalable structure.