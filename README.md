# Astro Flights: A Retro Hypercasual Word-Shooter 🚀👾

## ✨ Overview
Welcome to **Astro Flights**, a fast-paced, **hypercasual** retro arcade game for iOS where your vocabulary is your greatest weapon. Built entirely with modern Swift technologies, this game challenges players to type falling words to clear them before they overwhelm the screen. The project is a demonstration of a hybrid UI approach, seamlessly blending the power of **SpriteKit** for dynamic gameplay with the declarative elegance of **SwiftUI** for the user interface and state management.

## 🔋 Key Features
  * 🕹️ **Two Dynamic Game Modes** — Engage with words in unique ways:
      * **Shoot The Letter (STL)**: Pilot a spaceship and shoot down the correct letters in sequence to destroy incoming asteroid words.
      * **Fill In The Blanks (FITB)**: A classic challenge where players must quickly type the missing letters to complete the word.
  * 🏆 **GameKit Integration** — Compete with players worldwide\! The game includes full support for **Leaderboards** to track high scores and **Achievements** to reward skillful gameplay.
  * 🎨 **Hybrid UI System** — A modern development approach combining:
      * **SpriteKit**: For the core game loop, physics, animations, particle effects (explosions, wind), and player controls.
      * **SwiftUI**: For all UI elements, including the Heads-Up Display (HUD), score, health, pause menu, and game over screens. This allows for rapid UI development and clean state management.
  * 💾 **Local Data Persistence** — Utilizes **SwiftData** to efficiently manage and store the game's word lists locally on the device.
  * 🌌 **Immersive Retro Experience** — Features a custom-built **parallax background** manager, pixel-perfect assets, classic arcade fonts, and engaging sound effects to create a nostalgic feel.
  * 햅 **Haptic & Audio Feedback** — Enhances the user experience with carefully timed sound effects and haptic feedback for key game events like shooting, correct/incorrect answers, and explosions.

## 🧑‍💻 How It Works
1.  **Game State Management**: A central `GameState` object (an `ObservableObject`) manages all core logic, including score, health, the current word, and game status (`isPaused`, `isGameOver`).
2.  **SwiftUI View Layer**: The main `STLGameView` or `FITBGameView` observes the `GameState`. It renders the HUD and presents overlays (like the pause or game over menu) based on the state's properties.
3.  **SpriteKit Scene Layer**: The `SpriteView` hosts the `SKScene`, where all the action happens. The scene is responsible for:
      * Rendering the player's spaceship, falling word obstacles, and background effects.
      * Handling player input (touch gestures for movement and shooting).
      * Managing physics and detecting collisions between game elements (bullets, obstacles, player).
4.  **Two-Way Communication**: The `SKScene` holds a reference to the `GameState` to update it when game events occur (e.g., a letter is shot, the player takes damage). In turn, when the `GameState` changes (e.g., a new word is selected), it triggers updates in both the SwiftUI `View` and the `SKScene`.

## ⚙️ Tech Stack
  * 📱 **Framework**: SwiftUI
  * 🕹️ **Game Engine**: SpriteKit
  * 🏆 **Services**: GameKit (Game Center)
  * 💾 **Database**: SwiftData
  * 🎵 **Audio**: AVFoundation
  * 햅 **Haptics**: Core Haptics

## 🌟 See Astro Flights in Action\! 📸
<div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px;">  
    <img src="https://drive.google.com/uc?id=1H1jlUPdoZoDiRfdjJtN8VDFI2vLliwb0" alt="Screenshot 1" style="width: 30%;"/>
    <img src="https://drive.google.com/uc?id=15tst8NzmzJ6VMkcSH9RuHKCz1mwjgZHi" alt="Screenshot 2" style="width: 30%;"/>
    <img src="https://drive.google.com/uc?id=1XI13I78xvS9uOUDxZ0M0ruZ2YUQ-pKgj" alt="Screenshot 3" style="width: 30%;"/>
    <img src="https://drive.google.com/uc?id=1v3_4oiC28v-_GHWCtcG8PIrnpFWKCEDD" alt="Screenshot 4" style="width: 30%;"/>
    <img src="https://drive.google.com/uc?id=15VQ1HaEYrQ30HfNz9BvzAX9hcyfymXWj" alt="Screenshot 5" style="width: 30%;"/>
    <img src="https://drive.google.com/uc?id=15G4A4HGxMGsmMhQj9uazWUwt_RkuD9c4" alt="Screenshot 5" style="width: 30%;"/>
    <img src="https://drive.google.com/uc?id=1zKfB120Rjng8ik8V1OCe3K2HtmGVEckM" alt="Screenshot 5" style="width: 30%;"/>
</div>

## 🚀 Getting Started
Follow these steps to get Astro Flights up and running on your local machine using Xcode.

### Prerequisites
  * [macOS](https://www.google.com/search?q=https://www.apple.com/macos/) (latest version recommended)
  * [Xcode](https://developer.apple.com/xcode/) (version 15 or higher)
  * An active [Apple Developer Account](https://developer.apple.com/programs/enroll/) (required for Game Center features)

### Installation & Setup
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/streynaldo/WordInvader.git
    cd astroflights
    ```

2.  **Open the project in Xcode:**
      * Double-click the `.xcodeproj` file to launch the project.

3.  **Configure Signing & Capabilities:**
      * In the Project Navigator, select the project file, then select the main target.
      * Go to the **"Signing & Capabilities"** tab.
      * Select your developer account from the **"Team"** dropdown.
      * Ensure **Game Center** is added as a capability.

4.  **Run the application:**
      * Select an iOS Simulator or a connected physical device from the scheme menu.
      * Press the **Run** button (▶︎) or use the shortcut `Cmd + R`.

## 🤝 Contributor
  * 🧑‍💻 **Stefanus Reynaldo** : [@streynaldo](https://github.com/streynaldo)
  * 🧑‍💻 **Louis Fernando** : [@LouisFernando1204](https://github.com/LouisFernando1204)
  * 🧑‍💻 **Christian Sinaga** : [@chrisndrews](https://github.com/chrisndrews)
