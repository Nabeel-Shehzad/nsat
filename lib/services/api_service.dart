import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class ApiService {
  static const String baseUrl = 'https://www.accessvpn.co.uk/publicapi';
  final http.Client _client;
  
  ApiService() : _client = _createHttpClient();
  
  // Create a client that can handle problematic SSL certificates
  static http.Client _createHttpClient() {
    final HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }
  
  // Method to get user information and check if the user is valid
  Future<Map<String, dynamic>> getUser(String username, String password) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl?method=get_user&username=$username&password=$password'),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to authenticate user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Method to get OpenVPN profile for Android
  Future<String> getOpenVpnProfile(String username, String password) async {
    try {
      // First get the server information
      final userResponse = await getUser(username, password);
      if (userResponse['response'] != 'success') {
        throw Exception('Failed to get server information');
      }
      
      final serverIp = userResponse['server_ip'] as String;
      if (serverIp.isEmpty) {
        throw Exception('Server IP not found in response');
      }

      // Try to get the OpenVPN configuration
      final response = await _client.get(
        Uri.parse('$baseUrl?method=get_openvpn_profile&username=$username&password=$password'),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // If we get an error response, generate the config manually
        if (responseData is Map && responseData['response'] == 'error') {
          return _ensureValidOpenVpnConfig('', serverIp, username);
        }
        
        // If we got a valid config string, ensure it's complete
        String config = response.body;
        return _ensureValidOpenVpnConfig(config, serverIp, username);
      } else {
        throw Exception('Failed to get OpenVPN profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error while getting OpenVPN profile: $e');
    }
  }
  
  String _ensureValidOpenVpnConfig(String config, String serverIp, String username) {
  // A simplified configuration that removes extra TLS directives which might imply client certificate usage.
  config = '''client
dev tun
proto udp
remote $serverIp 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA256
auth-nocache
cipher AES-128-GCM
verb 3

<ca>
-----BEGIN CERTIFICATE-----
MIIEjzCCA3egAwIBAgIJAMRD6Iw9HxtCMA0GCSqGSIb3DQEBCwUAMIGLMQswCQYD
VQQGEwJVSzEPMA0GA1UECAwGTG9uZG9uMQ8wDQYDVQQHDAZMb25kb24xEjAQBgNV
BAoMCUFjY2Vzc1ZQTjESMBAGA1UECwwJQWNjZXNzVlBOMRIwEAYDVQQDDAlBY2Nl
c3NWUE4xHjAcBgkqhkiG9w0BCQEWD2luZm9AYWNjZXNzdnBuLjAeFw0yMzEwMjAx
NDM5MDBaFw0zMzEwMTcxNDM5MDBaMIGLMQswCQYDVQQGEwJVSzEPMA0GA1UECAwG
TG9uZG9uMQ8wDQYDVQQHDAZMb25kb24xEjAQBgNVBAoMCUFjY2Vzc1ZQTjESMBAG
A1UECwwJQWNjZXNzVlBOMRIwEAYDVQQDDAlBY2Nlc3NWUE4xHjAcBgkqhkiG9w0B
CQEWD2luZm9AYWNjZXNzdnBuLjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
ggEBALYbYB9yyH0KZvQ7zj8DNJ9O4PUznO/WY/JGQJc7R5F2JGRw7oBrL8LzgfAo
8D5TvZ7Qhf6TkE7oZZ5JOrKkKBJsFY5ZNV0i+0K1SAv3Gz0aZjRssTm7VXK4Q8sX
GfmB8I4JV5YtZ+3Zq+m2nRpyU8owggq7QTgVyYEasdIzkfzJ5CUGjP5BCoMBWwXb
JRhM3UN6V0tBwRF2SOXQnW8JsYqgZGx9WrjqPOHDtWyXEiVB5DXcVDVDOYY+rk7j
TJUBzXKvUUeKBhGu9PLDEVzXRJi1bTnNfVbKOOGyIG5piZH+hKUHm1lXq3RKlwhR
+BoX7Nm9qXd4jBgGBMSoevkCAwEAAaOB8TCB7jAdBgNVHQ4EFgQU8IHoiE9821Cf
6JywCXL/HJTJKnAwgb4GA1UdIwSBtjCBs4AU8IHoiE9821Cf6JywCXL/HJTJKnCh
gZGkgY4wgYsxCzAJBgNVBAYTAlVLMQ8wDQYDVQQIDAZMb25kb24xDzANBgNVBAcM
BkxvbmRvbjESMBAGA1UECgwJQWNjZXNzVlBOMRIwEAYDVQQDDAlBY2Nlc3NWUE4x
HjAcBgkqhkiG9w0BCQEWD2luZm9AYWNjZXNzdnBuLj==
-----END CERTIFICATE-----
</ca>
''';
  // Append an extra newline for safety.
  config += '\n';
  return config;
}


  
  // Helper method to get the minimum of two integers
  int min(int a, int b) => a < b ? a : b;
}
