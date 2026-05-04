import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String _baseUrl = 'https://track.xssecure.com';
  static const String _apiKey  = 'SMARTPARENTAPP2017';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/x-www-form-urlencoded',
    'androidkey': _apiKey,
  };

  static Future<Map<String, dynamic>?> post(
    String endpoint,
    Map<String, String> body,
  ) async {
    try {
      body['androidkey'] = _apiKey;
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('API Error [$endpoint]: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('API Error [$endpoint]: $e');
    }
    return null;
  }

  // Get live bus location
  static Future<Map<String, dynamic>?> getLiveLocation(
      String elementId, String mobileNumber) async {
    return post('/livetrack', {
      'elementID': elementId,
      'mobileNumber': mobileNumber,
    });
  }

  // Get attendance
  static Future<Map<String, dynamic>?> getAttendance(
      String mobileNumber, String month, String year) async {
    return post('/getattendance', {
      'mobileNumber': mobileNumber,
      'month': month,
      'year': year,
    });
  }

  // Associate child with parent
  static Future<Map<String, dynamic>?> associateChild(
      String mobileNumber, String uniqueId) async {
    return post('/assocelement', {
      'mobileNumber': mobileNumber,
      'uniqueID': uniqueId,
    });
  }
}
