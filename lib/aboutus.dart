import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("About Us"),
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/vector-nutrition-logo_809747-141.jpg'), // Replace with your logo
              ),
            ),
            SizedBox(height: 10),

            // App Name
            Text(
              "NutriScan",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            SizedBox(height: 5),

            // Short Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Helping you make healthier food choices with AI-powered ingredient analysis.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            SizedBox(height: 20),

            // Feature List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  _buildFeatureTile(Icons.scanner, "Barcode Scanner",
                      "Scan food products and get instant quality ratings."),
                  _buildFeatureTile(Icons.health_and_safety, "Health Ratings",
                      "AI-generated nutrition scores based on ingredients."),
                  _buildFeatureTile(Icons.access_time, "Detailed Analysis",
                      "Get insights into nutritional value and health impact."),
                ],
              ),
            ),
            SizedBox(height: 30),

            // Contact Info
            Text(
              "Contact Us",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            SizedBox(height: 10),

            // Email
            _buildContactRow(Icons.email, "support@nutriscan.com"),
            _buildContactRow(Icons.web, "www.nutriscan.com"),
            _buildContactRow(Icons.phone, "+1-234-567-8901"),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Feature Tile
  Widget _buildFeatureTile(IconData icon, String title, String description) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Colors.green[700], size: 30),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }

  // Contact Info Row
  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.green[700]),
          SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
