import 'package:openvpn_flutter/openvpn_flutter.dart';

class VpnService {
  final OpenVPN _openVPN = OpenVPN();
  bool _isInitialized = false;
  Function(VpnStatus)? _onVpnStatusChanged;
  
  Future<void> initialize({
    required String providerBundleIdentifier,
    required String localizedDescription,
    Function(VpnStatus)? onVpnStatusChanged,
  }) async {
    if (_isInitialized) return;
    
    _onVpnStatusChanged = onVpnStatusChanged;
    
    _openVPN.initialize(
      localizedDescription: localizedDescription,
      providerBundleIdentifier: providerBundleIdentifier,
      groupIdentifier: 'group.$providerBundleIdentifier'
    );
    
    _setupStatusMonitoring();
    
    _isInitialized = true;
  }
  
  void _setupStatusMonitoring() {
    Future.doWhile(() async {
      if (!_isInitialized) return false;
      
      try {
        final status = await _openVPN.status();
        final vpnStatus = _convertToVpnStatus(status);
        
        if (_onVpnStatusChanged != null) {
          _onVpnStatusChanged!(vpnStatus);
        }
      } catch (e) {
        // Ignore errors during status check
      }
      
      await Future.delayed(const Duration(seconds: 1));
      return true;
    });
  }
  
  VpnStatus _convertToVpnStatus(dynamic status) {
    if (status is String) {
      switch (status.toLowerCase()) {
        case "connected":
          return VpnStatus.connected;
        case "connecting":
          return VpnStatus.connecting;
        case "disconnected":
          return VpnStatus.disconnected;
        case "disconnecting":
          return VpnStatus.disconnecting;
        case "error":
          return VpnStatus.error;
        default:
          return VpnStatus.idle;
      }
    }
    return VpnStatus.idle;
  }
  
  Future<void> connect({
    required String config,
    required String username,
    required String password,
    String? serverAddress,
    String? sharedSecret,
  }) async {
    if (!_isInitialized) {
      throw Exception('VPN service not initialized');
    }

    try {
      // Print config for debugging
      print('Connecting with config length: ${config.length}');
      print('Config preview: ${config.substring(0, config.length > 100 ? 100 : config.length)}...');
      
      // Ensure config is properly formatted with Unix-style line endings
      config = config.replaceAll('\r\n', '\n');
      
      await _openVPN.connect(
        config,
        username,
        password: password,
        certIsRequired: false,
        bypassPackages: [],
      );
    } catch (e) {
      print('VPN connection error: $e');
      throw Exception('Failed to connect to VPN: $e');
    }
  }

  Future<void> disconnect() async {
    if (!_isInitialized) return;
    try {
      _openVPN.disconnect();
    } catch (e) {
      throw Exception('Failed to disconnect from VPN: $e');
    }
  }
  
  Future<bool> isConnected() async {
    if (!_isInitialized) return false;
    try {
      final status = await _openVPN.status();
      return _convertToVpnStatus(status) == VpnStatus.connected;
    } catch (e) {
      return false;
    }
  }
}

enum VpnStatus {
  idle,
  connecting,
  connected,
  disconnecting,
  disconnected,
  error,
}
