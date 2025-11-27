# Firebase Setup Instructions

## Step 1: Add Firebase SDK via Swift Package Manager

1. Open your project in Xcode
2. Go to **File → Add Package Dependencies...**
3. Enter this URL: `https://github.com/firebase/firebase-ios-sdk`
4. Click **Add Package**
5. Select these products:
   - ✅ **FirebaseAuth**
   - ✅ **FirebaseFirestore**
   - ✅ **FirebaseCore**
6. Click **Add Package**

## Step 2: Add GoogleService-Info.plist

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create one)
3. Click the gear icon → **Project Settings**
4. Scroll to **Your apps** section
5. Click the **macOS** icon (or iOS if macOS not available)
6. Enter your Bundle ID: `AgentText.AgentText`
7. Download **GoogleService-Info.plist**
8. Drag the file into your Xcode project (into the `AgentText` folder)
9. Make sure "Copy items if needed" is checked
10. Make sure it's added to the target

## Step 3: Enable Authentication

1. In Firebase Console, go to **Build → Authentication**
2. Click **Get started**
3. Enable **Email/Password** sign-in method
4. (Optional) Enable **Sign in with Apple** for production

## Step 4: Create Firestore Database

1. In Firebase Console, go to **Build → Firestore Database**
2. Click **Create database**
3. Start in **test mode** (for development)
4. Choose a location close to your users
5. Click **Enable**

## Step 5: Set Firestore Security Rules

1. In Firestore, go to **Rules** tab
2. Replace with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

3. Click **Publish**

## Step 6: Build and Run

The app should now connect to Firebase! The FirebaseService will automatically configure when the app launches.

