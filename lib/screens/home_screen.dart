import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vpn_provider.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NSAT VPN'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
              await vpnProvider.logout();
              
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<VpnProvider>(
        builder: (context, vpnProvider, child) {
          final user = vpnProvider.user;
          
          if (user == null) {
            return const Center(
              child: Text('Please log in to use the VPN'),
            );
          }
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Connection Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatusIndicator(vpnProvider),
                        const SizedBox(height: 16),
                        Text(
                          'Server: ${user.serverIp}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Status: ${user.status}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildConnectButton(vpnProvider),
                if (vpnProvider.errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    vpnProvider.errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildStatusIndicator(VpnProvider vpnProvider) {
    Color color;
    String status;
    IconData icon;
    
    if (vpnProvider.isConnected) {
      color = Colors.green;
      status = 'Connected';
      icon = Icons.check_circle;
    } else if (vpnProvider.isConnecting) {
      color = Colors.orange;
      status = 'Connecting...';
      icon = Icons.pending;
    } else {
      color = Colors.red;
      status = 'Disconnected';
      icon = Icons.cancel;
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
  
  Widget _buildConnectButton(VpnProvider vpnProvider) {
    if (vpnProvider.isConnecting) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.grey,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 16),
            Text('Connecting...'),
          ],
        ),
      );
    }
    
    if (vpnProvider.isConnected) {
      return ElevatedButton(
        onPressed: vpnProvider.disconnectVpn,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.red,
        ),
        child: const Text('Disconnect'),
      );
    }
    
    return ElevatedButton(
      onPressed: vpnProvider.connectVpn,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('Connect to VPN'),
    );
  }
}
