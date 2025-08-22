# LifeLens iOS

A comprehensive health monitoring application for iOS that integrates with HealthKit and wearable devices to provide real-time health insights.

## Features

- **HealthKit Integration**: Seamless integration with Apple Health for comprehensive health data
- **Real-time Monitoring**: Track vital signs including heart rate, ECG, blood oxygen, and more
- **Machine Learning**: Advanced on-device ML for pattern detection and health predictions
- **Wearable Integration**: Bluetooth connectivity with health monitoring devices
- **Interactive Visualizations**: Beautiful charts and dashboards for health metrics
- **Privacy-First**: All sensitive data processed on-device with end-to-end encryption
- **Biometric Security**: Face ID and Touch ID support for secure access

## Tech Stack

- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Architecture**: MVVM with Combine
- **Data Persistence**: Core Data + Keychain
- **Networking**: URLSession + Alamofire
- **Machine Learning**: Core ML + Create ML
- **Health Integration**: HealthKit Framework
- **Charts**: Swift Charts

## Requirements

- Xcode 15.0 or later
- iOS 17.0+ (minimum deployment target)
- Swift 5.9+
- macOS Sonoma or later for development

## Setup

1. Clone the repository:
```bash
git clone https://github.com/Edprevenza/LifeLens-ios.git
cd LifeLens-ios
```

2. Open the project in Xcode:
```bash
open LifeLens/LifeLens.xcodeproj
```

3. Select your development team in the project settings

4. Configure the API endpoints in `ProductionConfig.swift` if needed

5. Build and run the project on a simulator or physical device

## Building

### Build for Simulator
```bash
cd LifeLens
./build_sim.sh
```

### Build for Device
```bash
cd LifeLens
./build_ios.sh
```

### Run Tests
```bash
xcodebuild test -project LifeLens/LifeLens.xcodeproj -scheme LifeLens -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Project Structure

```
LifeLens/
├── LifeLens/
│   ├── Components/         # Reusable UI components
│   ├── ML/                 # Machine learning models and services
│   ├── Managers/           # Business logic managers
│   ├── Services/           # API and data services
│   ├── Utilities/          # Helper classes and extensions
│   ├── Views/              # SwiftUI views
│   │   ├── Authentication/ # Login and registration views
│   │   ├── Charts/         # Data visualization components
│   │   └── Components/     # Shared view components
│   ├── models/             # Data models
│   └── ProductionConfig.swift # App configuration
├── LifeLensTests/          # Unit tests
└── LifeLensUITests/        # UI tests
```

## Key Features

### Health Monitoring
- ECG monitoring with real-time waveform display
- Heart rate and HRV tracking
- Blood oxygen saturation monitoring
- Body temperature tracking
- Sleep analysis
- Activity and workout tracking

### Machine Learning Capabilities
- Anomaly detection in health metrics
- Predictive health insights
- Pattern recognition for early warning signs
- On-device processing for privacy

### Security & Privacy
- HealthKit authorization management
- Keychain storage for sensitive data
- Biometric authentication
- Certificate pinning for API calls
- Local data encryption

## Permissions

The app requires the following permissions:
- **HealthKit**: Read/write health data
- **Bluetooth**: Connect to wearable devices
- **Notifications**: Health alerts and reminders
- **Location**: When using outdoor workout features
- **Camera**: For document/prescription scanning (optional)

## HealthKit Data Types

The app can read and write the following HealthKit data:
- Heart Rate
- Blood Oxygen
- Body Temperature
- ECG
- Sleep Analysis
- Workout Data
- Activity Rings
- Respiratory Rate

## Contributing

Please read the contributing guidelines before submitting pull requests.

## License

This project is proprietary software. All rights reserved.

## Support

For support, please contact the development team or create an issue in the repository.

## Acknowledgments

- Built with SwiftUI and HealthKit
- Uses Core ML for on-device machine learning
- Integrates with Apple Health ecosystem