# AgentText

A macOS application for managing and deploying iMessage agents with a marketplace for sharing and discovering agents.

## Features

- 🔐 **Firebase Authentication** - Secure user authentication
- 📱 **iMessage Integration** - Full disk access for message management
- 🏪 **Agent Marketplace** - Browse, install, and share agents
- 👨‍💻 **Developer Console** - Create and upload custom agents
- 📊 **Dashboard** - Manage your installed agents

## Prerequisites

- **macOS** 12.0 or later
- **Xcode** 14.0 or later
- **Swift** 5.7 or later
- **Firebase Account** (for authentication and database)

## Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd AgentText
```

### 2. Open in Xcode

```bash
open AgentText.xcodeproj
```

### 3. Configure Firebase

Follow the detailed instructions in [FIREBASE_SETUP.md](./FIREBASE_SETUP.md) to:

1. Add Firebase SDK via Swift Package Manager
2. Download and add `GoogleService-Info.plist`
3. Enable Firebase Authentication
4. Set up Firestore Database

**Important:** `GoogleService-Info.plist` is not included in the repository. You must download it from your Firebase Console and add it to the project.

### 4. Grant Full Disk Access

The app requires Full Disk Access to interact with iMessage:

1. Go to **System Settings** → **Privacy & Security** → **Full Disk Access**
2. Add the AgentText app (or Terminal if running from Xcode)
3. Restart the app

### 5. Build and Run

1. Select your target device/simulator in Xcode
2. Press `Cmd + R` or click the Run button
3. The app will launch and prompt for authentication

## Project Structure

```
AgentText/
├── AgentText/
│   ├── AgentTextApp.swift          # Main app entry point
│   ├── Models/
│   │   └── Agent.swift             # Agent data model
│   ├── Screens/
│   │   ├── DashboardView.swift
│   │   ├── LoginView.swift
│   │   ├── SignInView.swift
│   │   ├── MarketplaceView.swift
│   │   ├── MyAgentsView.swift
│   │   ├── DeveloperConsoleView.swift
│   │   ├── DeveloperUploadForm.swift
│   │   └── PermissionView.swift
│   ├── Services/
│   │   ├── AuthManager.swift       # Firebase authentication
│   │   └── FirebaseService.swift   # Firebase configuration
│   └── Components/
│       ├── LogoView.swift
│       └── LuminescentCard.swift
└── FIREBASE_SETUP.md               # Firebase setup guide
```

## Development

### Adding Dependencies

Dependencies are managed via Swift Package Manager. To add a new package:

1. In Xcode: **File** → **Add Package Dependencies...**
2. Enter the package URL
3. Select the products you need
4. Click **Add Package**

### Code Style

- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Keep views modular and reusable

## Troubleshooting

### App won't start / Firebase errors

- Ensure `GoogleService-Info.plist` is added to the project
- Verify Firebase SDK packages are installed
- Check that the Bundle ID matches your Firebase app

### Full Disk Access not working

- Make sure the app is added in System Settings
- Restart the app after granting permissions
- Check Console.app for permission errors

### Build errors

- Clean build folder: **Product** → **Clean Build Folder** (`Cmd + Shift + K`)
- Delete derived data if needed
- Ensure all Swift Package Manager dependencies are resolved

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

[Add your license here]

## Support

For issues and questions, please open an issue on GitHub.

