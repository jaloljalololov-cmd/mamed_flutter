import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const candidatePrefixes = [
    '',
    'hs/mamed',
    'hs/mobile',
    'hs/api',
    'hs',
  ];

  Future<Map<String, String>> _getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'host': prefs.getString('serverHost') ?? '',
      'port': prefs.getString('serverPort') ?? '',
      'dbName': prefs.getString('serverDbName') ?? '',
      'username': prefs.getString('username') ?? '',
      'password': prefs.getString('password') ?? '',
    };
  }

  String _buildUrl(String host, String port, String dbName, String prefix, String endpoint) {
    var cleanHost = host.trim();
    if (!cleanHost.startsWith('http://') && !cleanHost.startsWith('https://')) {
      cleanHost = 'http://$cleanHost';
    }
    var base = cleanHost;
    if (port.trim().isNotEmpty) {
      base = '$base:${port.trim()}';
    }
    var fullPath = dbName.trim();
    if (prefix.isNotEmpty) {
      fullPath = fullPath.isEmpty ? prefix : '$fullPath/$prefix';
    }
    if (fullPath.isNotEmpty) {
      base = '$base/$fullPath';
    }
    if (!base.endsWith('/')) {
      base = '$base/';
    }
    return '$base$endpoint';
  }

  Map<String, String> _getHeaders(String username, String password) {
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (username.isNotEmpty) {
      final auth = base64Encode(utf8.encode('$username:$password'));
      headers['Authorization'] = 'Basic $auth';
    }
    return headers;
  }

  Future<dynamic> getRequest(String endpoint) async {
    final creds = await _getCredentials();
    final prefs = await SharedPreferences.getInstance();
    final cachedPrefix = prefs.getString('workingPrefix') ?? '';

    final prefixesToTry = [
      if (cachedPrefix.isNotEmpty) cachedPrefix,
      ...candidatePrefixes.where((p) => p != cachedPrefix)
    ];

    String lastError = 'Сервер не настроен';

    for (var prefix in prefixesToTry) {
      final urlStr = _buildUrl(creds['host']!, creds['port']!, creds['dbName']!, prefix, endpoint);
      final headers = _getHeaders(creds['username']!, creds['password']!);

      try {
        final response = await http.get(Uri.parse(urlStr), headers: headers).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          await prefs.setString('workingPrefix', prefix);
          return jsonDecode(utf8.decode(response.bodyBytes));
        } else {
          lastError = 'HTTP ${response.statusCode}';
        }
      } catch (e) {
        lastError = e.toString();
      }
    }
    throw Exception(lastError);
  }

  Future<bool> postPrescriptionOrCancellation(String endpoint, Map<String, dynamic> body) async {
    final creds = await _getCredentials();
    final prefs = await SharedPreferences.getInstance();
    final cachedPrefix = prefs.getString('workingPrefix') ?? '';

    final prefixesToTry = [
      if (cachedPrefix.isNotEmpty) cachedPrefix,
      ...candidatePrefixes.where((p) => p != cachedPrefix)
    ];

    final cleanEp = endpoint.replaceAll('/', '');
    final endpointsToTry = <String>[
      '$cleanEp/',
      cleanEp,
    ];

    if (cleanEp.toLowerCase().contains('prescription')) {
      endpointsToTry.addAll(['postPrescriptions/', 'postPrescriptions', 'createPrescription/', 'createPrescription', 'postDocument/', 'postDocument']);
    } else if (cleanEp.toLowerCase().contains('cancellation')) {
      endpointsToTry.addAll(['postCancellations/', 'postCancellations', 'createCancellation/', 'createCancellation', 'postCancellationDoc/', 'postCancellationDoc']);
    }

    String lastServerError = '';

    for (var prefix in prefixesToTry) {
      final jsonBody = jsonEncode(body);
      final headers = _getHeaders(creds['username']!, creds['password']!);

      for (var ep in endpointsToTry) {
        final urlStr = _buildUrl(creds['host']!, creds['port']!, creds['dbName']!, prefix, ep);

        try {
          final response = await http.post(Uri.parse(urlStr), headers: headers, body: jsonBody).timeout(const Duration(seconds: 10));
          if (response.statusCode == 200 || response.statusCode == 201) {
            await prefs.setString('workingPrefix', prefix);
            return true;
          } else {
            lastServerError = '1С HTTP ${response.statusCode}: ${response.body}';
          }
        } catch (e) {
          lastServerError = e.toString();
        }
      }
    }
    throw Exception(lastServerError.isNotEmpty ? lastServerError : 'Ошибка подключения к 1С');
  }
}
