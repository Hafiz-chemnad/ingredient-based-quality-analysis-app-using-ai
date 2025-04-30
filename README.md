# nutri-scan app

A new Flutter project.

## Getting Started

This project is an AI-powered mobile application designed to analyze the quality of food products based on their listed ingredients. The app leverages machine learning and natural language processing to provide users with a health-based quality rating of products by scanning nutritional fact labels or barcodes.

Key features include:

Barcode Scanning: Quickly identify food products by scanning barcodes. If the product exists in the database, the app fetches and displays the quality score and relevant details.

Image-to-Text Conversion: If the product is not in the database, users can capture an image of the nutritional label. Google ML Kit is used to extract text (OCR) from the image.

AI-Powered Ingredient Analysis: Extracted ingredients are processed using a gemini ai to evaluate each component’s health impact.

Quality Scoring System: The app generates a quality score (e.g., out of 100), quality stage (e.g., Poor, Average, Good), and a summary explanation based on the analysis.

Flutter Frontend: A user-friendly mobile interface built with Flutter featuring a splash screen, barcode scanner, and options like “About Us” and “Help.”

Backend Integration: Python Flask backend integrated with MongoDB to handle product data, user interactions, and AI model requests.

This project aims to promote healthier food choices by offering a simple and intelligent way for users to evaluate what they consume.
This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
