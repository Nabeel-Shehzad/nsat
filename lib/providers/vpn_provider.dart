import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/vpn_service.dart';

class VpnProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final VpnService _vpnService = VpnService();
  
  User? _user;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isInitialized = false;
  String _errorMessage = '';
  
  User? get user => _user;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isInitialized => _isInitialized;
  String get errorMessage => _errorMessage;
  
  Future<void> initialize() async {
    try {
      await _vpnService.initialize(
        providerBundleIdentifier: 'com.app.nsat.vpn-extension',
        localizedDescription: 'NSAT VPN',
        onVpnStatusChanged: _handleVpnStatusChange,
      );
      _isInitialized = true;
      
      // Load saved credentials
      await _loadSavedCredentials();
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
      notifyListeners();
    }
  }
  
  void _handleVpnStatusChange(VpnStatus status) {
    switch (status) {
      case VpnStatus.connected:
        _isConnected = true;
        _isConnecting = false;
        break;
      case VpnStatus.connecting:
        _isConnecting = true;
        _isConnected = false;
        break;
      case VpnStatus.disconnected:
        _isConnected = false;
        _isConnecting = false;
        break;
      case VpnStatus.disconnecting:
        _isConnecting = false;
        break;
      case VpnStatus.error:
        _isConnected = false;
        _isConnecting = false;
        _errorMessage = 'VPN connection error';
        break;
      default:
        break;
    }
    notifyListeners();
  }
  
  Future<bool> login(String username, String password) async {
    try {
      _errorMessage = '';
      final response = await _apiService.getUser(username, password);
      
      if (response['response'] == 'success') {
        _user = User.fromJson(response, username, password);
        
        // Save credentials
        await _saveCredentials(username, password);
        
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Login failed: ${response['response']}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login error: $e';
      notifyListeners();
      return false;
    }
  }
  
  Future<void> connectVpn() async {
    if (_user == null) {
      _errorMessage = 'Please log in first';
      notifyListeners();
      return;
    }
    
    try {
      _isConnecting = true;
      _errorMessage = '';
      notifyListeners();
      
      // For Android, get OpenVPN profile
      if (defaultTargetPlatform == TargetPlatform.android) {
        String config;
        try {
          config = await _apiService.getOpenVpnProfile(
            _user!.username,
            _user!.password,
          );
        } catch (e) {
          _isConnecting = false;
          _errorMessage = e.toString();
          notifyListeners();
          return;
        }
        
        try {
          await _vpnService.connect(
            config: config,
            username: _user!.username,
            password: _user!.password,
          );
        } catch (e) {
          _isConnecting = false;
          _errorMessage = 'VPN connection failed: ${e.toString()}';
          notifyListeners();
        }
      } else {
        // For iOS, use IKEv2
        try {
          await _vpnService.connect(
            config: '',
            username: _user!.username,
            password: _user!.password,
            serverAddress: _user!.serverIp,
            sharedSecret: 'vpn123',
          );
        } catch (e) {
          _isConnecting = false;
          _errorMessage = 'VPN connection failed: ${e.toString()}';
          notifyListeners();
        }
      }
    } catch (e) {
      _isConnecting = false;
      _errorMessage = 'Failed to connect: $e';
      notifyListeners();
    }
  }
  
  Future<void> disconnectVpn() async {
    try {
      await _vpnService.disconnect();
      _isConnected = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to disconnect: $e';
      notifyListeners();
    }
  }
  
  Future<void> _saveCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('password', password);
  }
  
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    
    if (username != null && password != null) {
      await login(username, password);
    }
  }
  
  Future<void> logout() async {
    if (_isConnected) {
      await disconnectVpn();
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');
    
    _user = null;
    notifyListeners();
  }
}
