import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:barcode_scan2/barcode_scan2.dart' as barcode;
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ing_analysisapp/aboutus.dart';
import 'package:ing_analysisapp/help.dart';
import 'package:ing_analysisapp/splash_screen.dart'; // Add this import

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutri Scan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(), // Added const
        '/home': (context) => ProductScannerScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => ProductScannerScreen());
      },
    );
  }
}

class ProductScannerScreen extends StatefulWidget {
  @override
  _ProductScannerScreenState createState() => _ProductScannerScreenState();
}

class _ProductScannerScreenState extends State<ProductScannerScreen> {
  String _barcode = "";
  bool _isLoading = false;
  String _errorMessage = '';
  String _scannedIngredients = '';
  TextEditingController _productNameController = TextEditingController();
  TextEditingController _ingredientController = TextEditingController();
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();
  Future<void> _scanBarcode() async {
    try {
      var result = await barcode.BarcodeScanner.scan();
      setState(() {
        _barcode = result.rawContent;
      });
      if (_barcode.isNotEmpty) {
        _searchProduct(_barcode);
      } else {
        setState(() {
          _errorMessage = 'No barcode detected. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get barcode: $e';
      });
    }
  }

  Future<void> _searchProduct(String barcode) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      var url = Uri.parse('http://172.20.10.2:5000/product/$barcode');
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(productData: data),
          ),
        );
      } else {
        setState(() {
          _errorMessage =
              'Product not found. Please scan or enter ingredients.';
        });
        _showIngredientOptionsDialog();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error connecting to the server: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showIngredientOptionsDialog() {
    _ingredientController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Product Not Found'),
          content: Text('You can scan the ingredients or enter them manually.'),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Scan Ingredients'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _scanIngredients();
              },
            ),
            ElevatedButton(
              child: Text('Enter Manually'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _showSubmitForm(); // Show manual entry form
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _scanIngredients() async {
    _ingredientController.clear();
    try {
      var scannedText = await _scanText(); // Call the updated _scanText method
      setState(() {
        _scannedIngredients = scannedText;
        _ingredientController.text = _scannedIngredients;
      });
      _showSubmitForm();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to scan ingredients: $e';
      });
    }
  }

  Future<String> _scanText() async {
// Capture an image using the camera
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final RecognizedText recognizedText = await _textRecognizer
          .processImage(inputImage); // Use TextRecognizer and RecognizedText
      String scannedText = recognizedText.text.replaceAll('\n', ' ');
      ;
      if (scannedText.toLowerCase().contains("ingredients:")) {
        String ingredientsText = scannedText
            .substring(scannedText.toLowerCase().indexOf("ingredients:") + 12)
            .trim(); // Get the text after "ingredients:"
// Extract the ingredients list, stopping at the first period
       if (ingredientsText.contains('.')) {
         ingredientsText = ingredientsText.split('.').first;
       }
// Split the ingredients by commas and trim whitespace
//List<String> ingredients = ingredientsText.split(',').map((ingredient) => ingredient.trim()).toList();
//return ingredients.join(', '); // Return ingredients as a comma-separated string
        return ingredientsText;
      }else if (scannedText.toLowerCase().contains("ingredients")) {
        String ingredientsText = scannedText
            .substring(scannedText.toLowerCase().indexOf("ingredients") + 12)
            .trim(); // Get the text after "ingredients:"
// Extract the ingredients list, stopping at the first period
       if (ingredientsText.contains('.')) {
        ingredientsText = ingredientsText.split('.').first;
        }
// Split the ingredients by commas and trim whitespace
//List<String> ingredients = ingredientsText.split(',').map((ingredient) => ingredient.trim()).toList();
//return ingredients.join(', '); // Return ingredients as a comma-separated string
        return ingredientsText;
      }
       else {
        throw Exception("Ingredients not detected");
      }
    } else {
      throw Exception("No image selected");
    }
  }

  void _showSubmitForm() {
    _productNameController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Product Details'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _productNameController,
                  decoration: InputDecoration(labelText: 'Product Name'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _ingredientController,
                  decoration: InputDecoration(
                    labelText: 'Ingredients',
                    hintText:
                        'Enter ingredients (comma seperated)...', // This is the placeholder
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Submit'),
              onPressed: () {
                _submitProductDetails();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitProductDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      var url = Uri.parse('http://172.20.10.2:5000/analyze_product');
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'name': _productNameController.text,
          'barcode': _barcode,
          'ingredients': _ingredientController.text.split(','),
        }),
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(productData: data),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to save product.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error submitting product details: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive Scaling
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // ✅ Background Image (Responsive)
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ✅ Title Text at the Top Center (Scales Well)
          Positioned(
            top: screenHeight * 0.1,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'NUTRISCAN',
                style: TextStyle(
                  fontSize: screenWidth * 0.12, // Scales with screen width
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 247, 181, 0),
                  shadows: [
                    Shadow(
                      blurRadius: 5,
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✅ Main Content in the Center (Works for all screens)
          Center(
            child: _isLoading
                ? CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // ✅ Image Button for Barcode Scan

                      GestureDetector(
                        onTap: _scanBarcode,
                        child: Image.asset(
                          'assets/images/ssss-removebg-preview.png',
                          width: screenWidth * 0.6, // Responsive width
                          height: screenWidth * 0.6, // Maintain aspect ratio
                        ),
                      ),

                      //SizedBox(height: 2), // Spacing
                      Text(
                        'Scan Product Barcode',
                        style: TextStyle(
                            color: Colors.blue, fontSize: screenWidth * 0.04),
                      ),
                      if (_errorMessage.isNotEmpty)
                        Text(
                          _errorMessage,
                          style: TextStyle(
                              color: Colors.red, fontSize: screenWidth * 0.04),
                        ),
                      SizedBox(height: 100),
                    ],
                  ),
          ),

          // ✅ Help Button (Bottom Left)
          Positioned(
            bottom: screenHeight * 0.00,
            left: screenWidth * 0.02,
            child: GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HelpPage()));
              },
              child: Image.asset(
                'assets/images/help-removebg-preview.png',
                width: screenWidth * 0.45, // Responsive width
                height: screenWidth * 0.45,
              ),
            ),
          ),

          // ✅ About Us Button (Bottom Right)
          Positioned(
            bottom: screenHeight * 0.02,
            right: screenWidth * 0.05,
            child: GestureDetector(
              onTap: () {
                 Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AboutUsPage()));
                print("About Us Button Clicked");
              },
              child: Image.asset(
                'assets/images/abt-removebg-preview.png',
                width: screenWidth * 0.35,
                height: screenWidth * 0.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class ProductDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> productData;
  ProductDetailsScreen({required this.productData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Product Health Details"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 78, 172, 15),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProductCard(),
            SizedBox(height: 16),
            _buildHealthRatingCard(),
            SizedBox(height: 16),
            _buildIngredientCard(),
          ],
        ),
      ),
    );
  }

  // 📌 Modern Product Card
  Widget _buildProductCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.fastfood, size: 50, color: Colors.teal),
            SizedBox(height: 10),
            Text(
              productData['name'] ?? "Unknown Product",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 📌 Modern Health Rating Card
  Widget _buildHealthRatingCard() {
    double healthRating = productData['health_rating']?.toDouble() ?? 0.0;
    String healthRatingStage = productData['health_rating_stage'] ?? 'Unknown';
    String healthRatingComment = productData['health_rating_comment'] ?? '';

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Health Rating",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "$healthRating / 10",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _getRatingColor(healthRating),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Stage: $healthRatingStage",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (healthRatingComment.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  "💬 $healthRatingComment",
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 📌 Modern Ingredients Card with Chips
  Widget _buildIngredientCard() {
    List<String> ingredients =
        List<String>.from(productData['ingredients'] ?? []);

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ingredients",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: ingredients.map((ingredient) {
                return Chip(
                  label: Text(ingredient),
                  backgroundColor: Colors.teal.withOpacity(0.2),
                  labelStyle: TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // 📌 Color for Health Rating
  Color _getRatingColor(double rating) {
    if (rating >= 8) return Colors.green;
    if (rating >= 5) return Colors.orange;
    return Colors.red;
  }
}
