from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
import google.generativeai as genai
import os

app = Flask(__name__)
CORS(app)  # Enable CORS for frontend communication

# Configure MongoDB connection
MONGO_URI = "mongodb://localhost:27017/"  # Change if using a remote server
client = MongoClient(MONGO_URI)
db = client["nutriscan"]  # Database Name
products_collection = db["products"]  # Collection Name

# Helper function to call Gemini AI for product analysis
def analyze_with_gemini(ingredients, product_name):
    genai.configure(api_key="AIzaSyDv-cc3OcsAjqmaSFtnlOUI3qNY-fd30K8")

    # Create the model
    generation_config = {
        "temperature": 1,
        "top_p": 0.95,
        "top_k": 64,
        "max_output_tokens": 8192,
        "response_mime_type": "text/plain",
    }

    model = genai.GenerativeModel(
        model_name="gemini-1.5-flash",
        generation_config=generation_config,
    )
    chat_session = model.start_chat(history=[])

    # Prepare input for the model
    input_message = f"""Analyze the product '{product_name}' with ingredients: or under INGREDIENTS '{', '.join(ingredients)}'.
    Please rate the healthiness of the product on a scale of 1-10 based on its ingredients.
    Provide the response in this format:
    1st line: Health rating (just the number).
    2nd line: Health stage (one-line comment).
    3rd line: Summary (5 lines max)."""

    response = chat_session.send_message(input_message)
    response_lines = response.text.split("\n")

    print(f'RES: {str(response_lines)}')

    # Extract Health Rating, Stage, and Comments
    health_rating = float(response_lines[0].strip())  # First line contains the rating
    health_stage = response_lines[1].strip()  # Second line is the health stage
    health_comment = "\n".join(response_lines[2:]).strip()  # Remaining lines are the comments

    return health_rating, health_stage, health_comment

# Route to check if a product exists based on barcode
@app.route('/product/<string:barcode>', methods=['GET'])
def get_product(barcode):
    product = products_collection.find_one({"barcode": barcode}, {"_id": 0})  # Exclude MongoDB _id field

    if product:
        return jsonify(product)
    else:
        return jsonify({"message": "Product not found"}), 404

# Route to analyze the product and store in MongoDB
@app.route('/analyze_product', methods=['POST'])
def analyze_product():
    try:
        data = request.json
        product_name = data["name"]
        barcode = data["barcode"]
        ingredients = data["ingredients"]
        nutrient_facts = data.get("nutrient_facts", [])

        # Call Gemini AI for health analysis
        health_rating, health_stage, health_comment = analyze_with_gemini(ingredients, product_name)

        # Create product document
        new_product = {
            "name": product_name,
            "barcode": barcode,
            "ingredients": ingredients,
            "nutrient_facts": nutrient_facts,
            "health_rating": health_rating,
            "health_rating_stage": health_stage,
            "health_rating_comment": health_comment,
        }

        # Insert into MongoDB
        inserted_product = products_collection.insert_one(new_product)

        # Convert ObjectId to string and add it to the response
        new_product["_id"] = str(inserted_product.inserted_id)


        return jsonify(new_product), 200
    except Exception as e:
        print(f"Error adding product: {str(e)}")
        return jsonify({"error": f"Failed to analyze product: {str(e)}"}), 400

# Run the Flask app
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
