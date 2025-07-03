Medics







Project Overview

Medics is a Flutter application designed to provide a comprehensive solution for managing medications and pharmacies. The application allows users to search for medicines, view pharmacy information, and potentially offers more healthcare-related features. The project relies on Firebase for authentication and data management, and uses Flutter for building the user interface.

Key Features

•
User Authentication: User registration and login functionalities using Firebase Authentication.

•
Splash Screen: An engaging loading screen with animations upon application startup.

•
Medication Management: Populating a medication database (using medicine_database_helper.dart).

•
Flutter User Interface: An attractive and user-friendly design built with Flutter.

•
Firebase Integration: Utilizes Firebase for user and data management.

Technologies Used

•
Flutter: Google's UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.

•
Dart: The programming language used for developing Flutter applications.

•
Firebase: Google's app development platform that provides services like authentication and databases.

•
firebase_core: For Firebase initialization.

•
firebase_auth: For managing user authentication.



•
shared_preferences: For local storage of simple data on the device.

Getting Started

To get the Medics project up and running locally, follow these steps:

Prerequisites

Ensure you have the following installed on your machine:

•
Flutter SDK

•
Android Studio or VS Code with Flutter and Dart extensions.

•
A Firebase account and a configured project.

Setup

1.
Clone the Repository:

2.
Install Dependencies:

3.
Firebase Configuration:

•
Create a new Firebase project in the Firebase Console.

•
Add Android and iOS applications to your Firebase project.

•
Follow the instructions to add google-services.json (for Android) and GoogleService-Info.plist (for iOS) files to your project.

•
Ensure email/password authentication is enabled in Firebase Authentication.



4.
Run the Application:

Project Structure

Plain Text


medics/
├── android/                # Android project files
├── ios/                    # iOS project files
├── lib/
│   ├── api_service.dart    # API service (potentially for external service communication)
│   ├── db_test.dart        # Database test file
│   ├── firebase_options.dart # Firebase initialization options
│   ├── main.dart           # Main entry point of the application
│   └── screens/            # Various application screens
│       ├── DoctorDashboard/ # Doctor dashboard (if applicable)
│       ├── Home_Page/      # Home page
│       ├── login/          # Login screens
│       ├── Medics.dart     # (Potentially an additional file or typo)
│       ├── splash_screen.dart # Splash screen
│       └── welcome_page.dart # Welcome page
├── assets/                 # Assets such as images (e.g., logo.png)
├── pubspec.yaml            # Project definition and dependencies
└── README.md               # This file


Contributing

Contributions are welcome! If you'd like to contribute to this project, please follow these steps:

1.
Fork the repository.

2.
Create a new branch (git checkout -b feature/YourFeature).

3.
Make your changes.

4.
Commit your changes (git commit -m 'Add some feature').

5.
Push to the branch (git push origin feature/YourFeature).

6.
Open a Pull Request.

License

This project is licensed under the MIT License

