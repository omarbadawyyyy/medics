Medics
Failed to load image

View link
 (Replace with your project logo if available)

Medics is a Flutter-based mobile application designed to streamline medication and pharmacy management. It empowers users to search for medicines, access pharmacy details, and manage healthcare-related tasks with ease. Built with Flutter for a seamless cross-platform experience and integrated with Firebase for robust authentication and data management, Medics offers a modern and user-friendly interface for both patients and healthcare providers.

Table of Contents
Overview
Key Features
Technologies Used
Getting Started
Prerequisites
Setup Instructions
Project Structure
Contributing
Roadmap
Screenshots
License
Contact
Overview
Medics is a comprehensive healthcare solution aimed at simplifying medication management and pharmacy interactions. Whether you're a patient looking for medicine availability or a healthcare professional managing records, Medics provides an intuitive platform to meet your needs. The app leverages Flutter's cross-platform capabilities to deliver a consistent experience on both Android and iOS, with Firebase handling secure authentication and data storage.

Key Features
User Authentication: Secure registration and login using Firebase Authentication (email/password).
Splash Screen: Engaging animated splash screen for a polished user experience.
Medication Management: Search and manage medications with an integrated database (medicine_database_helper.dart).
Pharmacy Information: Access details about pharmacies and their offerings.
Responsive UI: Built with Flutter for a smooth and visually appealing interface across devices.
Firebase Integration: Real-time data management and secure user authentication.
Local Storage: Utilize shared_preferences for lightweight data persistence.
Technologies Used
Flutter: Cross-platform framework for building native mobile apps.
Dart: Programming language for Flutter development.
Firebase:
firebase_core: Core Firebase initialization.
firebase_auth: User authentication management.
Shared Preferences: Local storage for simple data persistence.
Other Dependencies: Refer to pubspec.yaml for a complete list.
Getting Started
Follow these steps to set up and run Medics locally.

Prerequisites
Ensure you have the following installed:

Flutter SDK: Install Flutter
Dart: Included with Flutter.
IDE: Android Studio or VS Code with Flutter and Dart plugins.
Firebase Account: Create a project on the Firebase Console.
Git: For cloning the repository.
Setup Instructions
Clone the Repository:
bash

Collapse

Wrap

Copy
git clone https://github.com/omarbadawyyyy/medics.git
cd medics
Install Dependencies:
bash

Collapse

Wrap

Copy
flutter pub get
Configure Firebase:
Create a Firebase project in the Firebase Console.
Add Android and iOS apps to your Firebase project.
Download google-services.json (for Android) and GoogleService-Info.plist (for iOS) and place them in the respective android/app and ios/Runner directories.
Enable Email/Password authentication in the Firebase Authentication section.
Run the Application:
bash

Collapse

Wrap

Copy
flutter run
Ensure an emulator or physical device is connected.
Access the App:
The app will launch on your device/emulator, starting with the splash screen followed by the welcome page or login screen.
Project Structure
text

Collapse

Wrap

Copy
medics/
├── android/                # Android-specific project files
├── ios/                    # iOS-specific project files
├── lib/
│   ├── api_service.dart    # Handles external API communication (if applicable)
│   ├── db_test.dart        # Database testing utilities
│   ├── firebase_options.dart # Firebase configuration
│   ├── main.dart           # Application entry point
│   └── screens/            # App screens
│       ├── DoctorDashboard/ # Doctor dashboard UI (if implemented)
│       ├── Home_Page/      # Main home page
│       ├── login/          # Login and registration screens
│       ├── Medics.dart     # Additional logic or screen (verify purpose)
│       ├── splash_screen.dart # Animated splash screen
│       └── welcome_page.dart # Welcome page for onboarding
├── assets/                 # Images, fonts, and other static assets
├── pubspec.yaml            # Project dependencies and configuration
└── README.md               # Project documentation
Contributing
We welcome contributions to enhance Medics! To contribute:

Fork the repository.
Create a new branch:
bash

Collapse

Wrap

Copy
git checkout -b feature/your-feature-name
Make your changes and commit:
bash

Collapse

Wrap

Copy
git commit -m "Add your feature description"
Push to your branch:
bash

Collapse

Wrap

Copy
git push origin feature/your-feature-name
Open a Pull Request on GitHub.
Please review our Contributing Guidelines (create this file if needed) for more details.

Roadmap
Add support for real-time notifications for medication reminders.
Implement pharmacy locator with Google Maps integration.
Enhance medication database with advanced search and categorization.
Add support for multi-language localization.
Introduce offline mode for core functionalities.
Screenshots
(Add screenshots of the app here to showcase the UI. Example placeholder below)


Splash Screen	Home Page	Login Screen
Failed to load image

View link
Failed to load image

View link
Failed to load image

View link
(Replace with actual screenshot paths once available)

License
This project is licensed under the MIT License. See the LICENSE file for details.

Contact
For questions, suggestions, or issues, reach out via:

GitHub Issues: Create an Issue
Email: omarbadawyyyy@example.com (Replace with your actual email)
Project Maintainer: Omar Badawyyyy
