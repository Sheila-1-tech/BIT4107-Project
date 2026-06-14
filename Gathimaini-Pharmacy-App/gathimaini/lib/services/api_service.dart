import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/drug_info.dart';

class ApiService {
  static const String _baseUrl = 'https://api.fda.gov/drug/label.json';

  static Future<DrugInfo?> fetchDrugInfo(String drugName) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?search=openfda.brand_name:"$drugName"&limit=1',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          return DrugInfo.fromJson(data['results'][0]);
        }
      }
      return null; // Return null if not found or error status
    } catch (e) {
      throw Exception(
        'Failed to connect to network. Check your internet connection.',
      );
    }
  }
}
