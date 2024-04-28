import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:dog_identifier/result.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:flutter/material.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {
  late File _image;
  String? result;
  List<String>? _labels;
  late tfl.Interpreter _interpreter;
  final picker = ImagePicker();
  double? confidenceScore;

  @override
  void initState() {
    loadModel().then((_) {
      loadLabels().then((loadedLabels) {
        setState(() {
          _labels = loadedLabels;
        });
      });
    });
    super.initState();
  }

  @override
  //Close the interpreter when the screen is disposed
  void dispose() {
    _interpreter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(
              height: 120,
            ),
            const Text(
              'Dog Breed Prediction',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1.4,
                fontFamily: 'SofiaSans',
                fontSize: 28,
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            Center(
              child: SizedBox(
                width: 350,
                child: Column(
                  children: [
                    Image.asset('assets/bg2.jpeg'),
                    const SizedBox(
                      height: 80,
                    )
                  ],
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          pickImageFromCamera();
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Capture a Photo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SofiaSans',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                Expanded(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          pickImageFromGallery();
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.photo,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Select a Photo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SofiaSans',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

 //Load the TensorFlow Lite model
  loadModel() async {
    try {
      _interpreter = await tfl.Interpreter.fromAsset('assets/model.tflite');
    } catch (e) {
      debugPrint('Error loading model: $e');
    }
  }

  //Function to pick a captured imaged from camera
  void pickImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _setImage(File(pickedFile.path));
    }
  }

  //Function to pick an image from gallery
  void pickImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _setImage(File(pickedFile.path));
    }
  }

  //Function to set the selected image and trigger inference
  void _setImage(File image) {
    setState(() {
      _image = image;
    });
    runInference();
  }

  // Function to preprocess the image
  Future<Uint8List> preprocessImage(File imageFile) async {
    // Decode the image
    img.Image? originalImage = img.decodeImage(await imageFile.readAsBytes());

    // Resize the image to match the model input size (331x331)
    img.Image resizedImage =
        img.copyResize(originalImage!, width: 331, height: 331);

    // Get the pixel values as a flat list and normalize them
    var pixels = resizedImage.getBytes().map((pixel) => pixel / 255.0).toList();

    // Convert to Uint8List
    return Float32List.fromList(pixels).buffer.asUint8List();
  }

  Future<List<String>> loadLabels() async {
    final labelsData =
        await DefaultAssetBundle.of(context).loadString('assets/labels.txt');
    return labelsData.split('\n');
  }


//Function to run inference
  void runInference() async {
    if (_labels == null) {
      return;
    }
    try {
      // Preprocess the image
      Uint8List inputBytes = await preprocessImage(_image);

      // Run inference
      var outputBuffer = List<double>.filled(1 * 120, 0).reshape([1, 120]);
      _interpreter.run(inputBytes, outputBuffer);
      List<double> output = outputBuffer[0];

      // Process the model output
      double maxScore = output.reduce(max);
      int highestProbIndex = output.indexOf(maxScore);
      double confidenceScore = output[highestProbIndex];
      String classificationResult = _labels![highestProbIndex];
      result = classificationResult;

      // Check if confidence score is below the threshold.
      if (confidenceScore < 0.3) {
        result = 'Not a dog'; // If it is then its not a dog.
      }
      // Navigate to the result screen
      navigateToResult(confidenceScore);
    } catch (e) {
      debugPrint('Error during inference: $e');
    }
  }

  //Navigate to the result screen
  void navigateToResult(double confidenceScore) {
    // Convert confidence score to percentage
    double confidenceScorePercentage = confidenceScore * 100;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          image: _image,
          result: result ?? 'Unknown',
          confidenceScore: confidenceScorePercentage,
        ),
      ),
    );
  }
}
