import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer';

class DogApiService {
  static Future<Map<String, dynamic>> fetchBreedInfo(String breedName) async {
    // Replace hyphens with underscores in breed name
    String finalBreedName = breedName.replaceAll('-', '_');


    final uri = Uri.parse('https://api.thedogapi.com/v1/breeds/search?q=$finalBreedName');
    // Log the URI to see the exact request being made
    log('Fetching breed info for: $finalBreedName at $uri');

    //Make the GET request
    final response = await http.get(
      uri,
      headers: {'x-api-key': 'live_Z0eCVGQs2vWjga70yEGmyzka5AJBpCqRXbuw3uXVyzbhH0OjPadfd48zt0NaxXuy'},
    );

    // Log the status code and response body to diagnose potential issues
    log('Response status code: ${response.statusCode}');
    log('Response body: ${response.body}');

    //Check the response status code and process the data if its 200
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        return data.first;
      }
    }
    return {}; // Return an empty map if breed information is not found
  }
}
