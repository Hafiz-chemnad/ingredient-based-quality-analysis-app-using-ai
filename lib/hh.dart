import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:barcode_scan2/barcode_scan2.dart' as barcode;
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart'; // Add this import
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
home: ProductScannerScreen(),
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
var url = Uri.parse('http://192.168.1.14:5000/product/$barcode');
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
_errorMessage = 'Product not found. Please scan or enter ingredients.';
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
final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
if (pickedFile != null) {
final inputImage = InputImage.fromFilePath(pickedFile.path);
final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage); // Use TextRecognizer and RecognizedText
String scannedText = recognizedText.text.replaceAll('\n', ' ');;
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
} else {
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
hintText: 'Enter ingredients (comma seperated)...', // This is the placeholder
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
var url = Uri.parse('http://192.168.1.14:5000/analyze_product');
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
return Scaffold(
appBar: AppBar(
title: Text('Nutri Scan'),
),
body: Center(
child: _isLoading
? CircularProgressIndicator()
: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: <Widget>[
ElevatedButton(
onPressed: _scanBarcode,
child: Text('Scan Barcode'),
),
SizedBox(height: 20),
Text(
'Scan Product Barcode',
style: TextStyle(color: Colors.blue),
),
if (_errorMessage.isNotEmpty)
Text(
_errorMessage,
style: TextStyle(color: Colors.red),
),
],
),
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
),
body: SingleChildScrollView( // Added to handle overflow
child: Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
_buildProductCard(), // Product Info card
SizedBox(height: 16),
_buildHealthRatingCard(), // Health Rating card
SizedBox(height: 16),
_buildIngredientCard(), // Ingredients card
],
),
),
),
);
}
// Product Info Card
Widget _buildProductCard() {
return Card(
elevation: 4.0,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
child: Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
"Product Name:",
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
SizedBox(height: 8),
Text(
"${productData['name']}",
style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
),
],
),
),
);
}
// Health Rating Card
Widget _buildHealthRatingCard() {
double healthRating = productData['health_rating']?.toDouble() ?? 0.0;
String healthRatingStage = productData['health_rating_stage'] ?? 'Unknown';
String healthRatingComment = productData['health_rating_comment'] ?? '';
return Card(
elevation: 4.0,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
child: Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
"Health Rating:",
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
SizedBox(height: 8),
Text(
"$healthRating / 10",
style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _getRatingColor(healthRating)),
),
SizedBox(height: 8),
Text(
"Stage: $healthRatingStage",
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
if (healthRatingComment.isNotEmpty)
Padding(
padding: const EdgeInsets.only(top: 8.0),
child: Text(
"Comment: $healthRatingComment",
style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
),
),
],
),
),
);
}
// Ingredients Card
Widget _buildIngredientCard() {
List<String> ingredients = List<String>.from(productData['ingredients'] ?? []);
return Card(
elevation: 4.0,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
child: Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
"Ingredients:",
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
SizedBox(height: 8),
for (var ingredient in ingredients)
Padding(
padding: const EdgeInsets.symmetric(vertical: 4.0),
child: Text(
ingredient,
style: TextStyle(fontSize: 16),
),
),
],
),
),
);
}
// Get color based on health rating
Color _getRatingColor(double rating) {
if (rating >= 8) {
return Colors.green;
} else if (rating >= 5) {
return Colors.orange;
} else {
return Colors.red;
}
}
}
