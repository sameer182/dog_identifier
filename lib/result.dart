import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dog_identifier/dog_api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share/share.dart';

class ResultScreen extends StatelessWidget {
  final File image;
  final String result;
  final double? confidenceScore;

  const ResultScreen({
    Key? key,
    required this.image,
    required this.result,
    this.confidenceScore,
  }) : super(key: key);

  //Method to share the prediction result and additional breed information
  void shareResult(
      BuildContext context, String breedName, String description) async {
    try {
      // Get bytes of the image
      List<int> bytes = await image.readAsBytes();
      // Convert bytes to Uint8List
      final Uint8List uint8List = Uint8List.fromList(bytes);

      // Create a message with the breed name and description
      final String message =
          'Hello, I identified this dog breed as: ${result.toUpperCase()} \n\nDescription: $description'
          '\n\nI hope you enjoyed watching :)';

      // Share the message along with the image
      await Share.shareFiles(
        ['${image.path}'],
        text: message,
      );
    } catch (e) {
      print('Error sharing: $e');
    }
  }

  //Method to build information tile for breed details
  Widget _buildInfoTile(String title, dynamic content) {
    if (title == 'Breed Image URL:') {
      return ListTile(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: content != null
            ? GestureDetector(
                onTap: () {
                  if (content is String) {
                    // Open the URL when tapped
                    launch(content);
                  }
                },
                child: Text(
                  content,
                  style: TextStyle(
                      color: Colors.blue, decoration: TextDecoration.underline),
                ),
              )
            : Text('N/A'),
      );
    } else {
      return ListTile(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(content ?? 'N/A'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight:
                MediaQuery.of(context).size.width,
            stretch: true,
            pinned: true,
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.file(
                image,
                fit: BoxFit.cover,
              ),
              stretchModes: [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
                StretchMode.fadeTitle,
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    result.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Confidence Score: ${confidenceScore?.toStringAsFixed(2) ?? 'N/A'}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  //Fetch the additional breed information from API
                  FutureBuilder<Map<String, dynamic>>(
                    future: DogApiService.fetchBreedInfo(result),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(
                            child: Text(
                                'ERROR, No Internet Connection \n\nPlease connect to the internet or wifi for breed information.'));
                      } else if (snapshot.hasData) {
                        final breedInfo = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInfoTile('Breed Name:',
                                breedInfo != null ? breedInfo['name'] : null),
                            _buildInfoTile(
                                'Bred for:',
                                breedInfo != null
                                    ? breedInfo['bred_for']
                                    : null),
                            _buildInfoTile(
                                'Breed Group:',
                                breedInfo != null
                                    ? breedInfo['breed_group']
                                    : null),
                            _buildInfoTile(
                                'Life Span:',
                                breedInfo != null
                                    ? breedInfo['life_span']
                                    : null),
                            _buildInfoTile(
                                'Temperament:',
                                breedInfo != null
                                    ? breedInfo['temperament']
                                    : null),
                            _buildInfoTile('Breed Origin:',
                                breedInfo != null ? breedInfo['origin'] : null),
                            _buildInfoTile(
                                'Breed Description:',
                                breedInfo != null
                                    ? breedInfo['description']
                                    : null),
                            _buildInfoTile(
                                'Breed Height:',
                                breedInfo != null && breedInfo['height'] != null
                                    ? '${breedInfo['height']['metric']} cm'
                                    : null),
                            _buildInfoTile(
                                'Breed Weight:',
                                breedInfo != null && breedInfo['weight'] != null
                                    ? '${breedInfo['weight']['metric']} kg'
                                    : null),
                            _buildInfoTile(
                                'Breed Image URL:',
                                breedInfo != null && breedInfo['image'] != null
                                    ? breedInfo['image']['url']
                                    : null),
                          ],
                        );
                      } else {
                        return const Center(child: Text('No data available'));
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  //Button to navigate back to home screen
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blueAccent, // Text color
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),

      //Floating action button for sharing the result
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final breedInfo = await DogApiService.fetchBreedInfo(result);
          if (breedInfo != null) {
            String breedName = result;
            String temperament = breedInfo['temperament'] ?? 'N/A';
            String bredFor = breedInfo['bred_for'] ?? 'N/A';
            String breedGroup = breedInfo['breed_group'] ?? 'N/A';
            String lifeSpan = breedInfo['life_span'] ?? 'N/A';
            String height = breedInfo['height']['metric'] ?? 'N/A';
            String weight = breedInfo['weight']['metric'] ?? 'N/A';
            String description =
                '$temperament \n\nBred For: $bredFor \n\nBreed Group: $breedGroup \n\nLife span: $lifeSpan '
                '\n\nHeight: $height cm \n\nWeight: $weight kg';
            shareResult(context, breedName, description);
          } else {
            // If breed information is not available, set description to "N/A"
            String breedName = 'N/A';
            String description = 'N/A';
            shareResult(context, breedName, description);
          }
        },
        tooltip: 'Share Result',
        child: const Icon(Icons.share),
      ),
    );
  }
}
