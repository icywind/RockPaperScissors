# Rock Paper Scissors - Hand Gesture Edition 🖐️

[![SwiftUI](https://img.shields.io/badge/SwiftUI-5%20stars-brightgreen.svg)](https://developer.apple.com/xcode/swiftui/)
[![iOS](https://img.shields.io/badge/iOS-17%2B-blue.svg)](https://developer.apple.com/ios/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A real-time **Rock Paper Scissors** game built with **SwiftUI** and **Core ML** for iOS. Play against an AI opponent using your **hand gestures** captured by the front-facing camera—no taps required!

## 🎮 Overview

Detects **Rock**, **Paper**, or **Scissors** hand poses in real-time using a trained ML model. The first gesture triggers a **3-second countdown**, then competes against the AI's random move. Complete with smooth animations and effects!

**Player 1:** You (camera gestures)  
**Player 2:** AI opponent

## ✨ Features

- **Real-time Hand Pose Recognition** via `RockPaperScissorClassifier.mlmodel` and `AVCaptureSession`
- **Camera Permissions & Error Handling** (front camera only)
- **3-Second Countdown Timer** on first detected gesture
- **AI Opponent** with random moves
- **Visual Feedback:**
  - **Win:** Confetti explosion on your area!
  - **Lose:** Pink tint overlay
  - **Tie:** Full-screen \"TIE!\" marquee effect
  - Shuffling animation for AI move reveal
- **Game State Management** with `GameViewModel` + `GameController`
- **Unit Tests** for game logic
- **Optimized Views:** `PlayerCameraAreaView`, `AIPlayerAreaView`, `ResultBoxView`

## 📱 Demo

<!-- Add a screen recording GIF here! Example: -->
<!-- ![Demo](demo.gif) -->

1. Show hand to camera → Gesture detected → Countdown
2. Hold pose → AI shuffles → Outcome revealed with effects!

## 🛠️ Setup & Run

1. Clone the repo:
   ```bash
   git clone https://github.com/yourusername/RockPaperScissors.git
   cd RockPaperScissors
   ```

2. Open in **Xcode**:
   ```
   open RockPaperScissors.xcodeproj
   ```

3. Select an **iOS Simulator** with camera support (iPhone 15 Pro or later recommended) or **physical device**.

4. **Build & Run** (⌘R)

5. **Grant Camera Permission** when prompted.

**Requirements:** iOS 17+, Xcode 15+

## 🏗️ Project Structure

```
RockPaperScissors/
├── View/                 # SwiftUI Views
├── ViewModel/            # Observable ViewModels
├── Model/                # HandMove enum
├── Controller/           # GameController, RoundStateMachine
├── RockPaperScissors.xcodeproj
└── Tests/
```

## 🚀 Future Roadmap

- **Real-Time Communication (RTC)**: Multiplayer over WebRTC for remote players
- **Advanced AI Player**: Smarter opponent (learn from user patterns, difficulty levels)
- **Custom Gestures & Themes**
- **Game Stats & Leaderboards**
- **Share Replay Feature**
- **macOS Catalyst Support**

Contributions welcome! See [TODO.md](TODO.md) for recent completions (e.g., special effects ✅).

## 🤝 Contributing

1. Fork & clone
2. Create feature branch: `git checkout -b feature/AmazingFeature`
3. Commit: `git commit -m 'Add amazing feature'`
4. Push & PR!

## 📄 License

MIT License - see [LICENSE](LICENSE) (add one if missing).

---

**Built with ❤️ using SwiftUI, Vision, Core ML by @chengr**
