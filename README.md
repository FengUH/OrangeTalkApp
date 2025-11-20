🍊 OrangeTalkApp — AI-Powered Citrus Assistant (Flutter)

OrangeTalkApp is a Flutter-based intelligent assistant designed for citrus growers.
It integrates disease diagnosis, market analytics & forecasting, fertilizer recommendations, case archives, and configurable API services into a single mobile application.

The app features a modular architecture, supports both iOS and Android, and is built for easy maintenance, extensibility, and real-world agricultural workflows.


📱 App Screenshots

<img width="600" height="671" alt="Screenshot 2025-11-19 at 10 31 20 PM" src="https://github.com/user-attachments/assets/164b7924-befb-4449-ab44-1b06ecf8a5a5" />

🚀 Key Features (Module Overview)

1. AI Disease Diagnosis

The diagnosis module enables users to either take a photo or select an existing image of a citrus leaf. After uploading, the AI model analyzes the leaf and returns the disease name, confidence score, and practical recommendations—such as pesticide options, watering guidance, and preventive measures. The diagnosis result is displayed immediately on the same page, and users can save any result directly to the case archive with a single tap.

2. Citrus Market Trends & Price Forecasting

The market module allows users to choose from multiple citrus varieties (such as Wogan, Sugar Orange, Gold Nugget, etc.) and view their daily price, price change, and short-term volatility. The page also displays a recent 7-day historical trend chart along with a 7-day forward forecast. Daily forecasted prices are shown in a scrollable list, giving growers a clear understanding of market movement to better plan sales and logistics. The data source can be a real API or local mock data depending on configuration.

3. Fertilizer Calculator

The fertilizer calculator provides personalized nutrient recommendations based on field area, tree age, soil type, seasonal fertilization plan, and target yield. After entering these parameters, the app calculates recommended N, P₂O₅, and K₂O amounts under different schemes (per-mu and national standard totals). Results are clearly displayed in structured cards, and users can copy the recommended values instantly for use in field operations.

4. Configurable API Center (Mock & HTTP Modes)

The settings module includes a complete API configuration center where users can switch between local Mock mode and real HTTP endpoints. Each service—disease recognition and market pricing—has its own configurable base URL, allowing for flexible integration with various backend environments. If the HTTP service is unavailable, the module automatically falls back to Mock mode to maintain usability during development or unstable network periods.

5. Case Archive Management

The case archive stores all previously generated diagnosis records in chronological order. Each entry includes the leaf image, disease name, timestamp, and confidence level. Users can browse the list, open a detailed view for any case, and review the AI-generated recommendations associated with it. Deletion is supported, and all data is persistently stored on the device, ensuring reliable offline access.


🏁 Getting Started

1. Clone the repository
git clone https://github.com/yourname/OrangeTalkApp.git
cd OrangeTalkApp

2. Install dependencies
flutter pub get

3. Run the app
flutter run

4. iOS setup (if building for iOS)
cd ios
pod install
cd ..
flutter run


🧪 Development Notes

Supports iOS and Android

For iOS, CocoaPods is required (pod install)

The app automatically falls back to Mock mode when the API is unavailable

Both Recognition API and Market API base URLs can be configured inside the app

📄 License

This project is provided as an open-source example.
You are free to modify, extend, and use it for further development.
