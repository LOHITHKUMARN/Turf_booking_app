import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class SocketService {
  IO.Socket? _socket;
  String? _token;
  String? _userId;

  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  bool get isConnected => _socket?.connected ?? false;

  void init({required String token, required String userId}) {
    _token = token;
    _userId = userId;

    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
    }

    final serverUrl = ApiConstants.baseUrl.split('/api')[0];
    log('Connecting to Socket server: $serverUrl');

    _socket = IO.io(serverUrl, 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': _token})
        .enableAutoConnect()
        .build()
    );

    _socket!.onConnect((_) {
      log('Socket connected: ${_socket!.id}');
      _socket!.emit('joinRole', 'customer');
    });

    _socket!.onDisconnect((_) => log('Socket disconnected'));
    _socket!.onConnectError((data) => log('Socket connect error: $data'));
    _socket!.onError((data) => log('Socket error: $data'));
  }

  void joinTurfRoom(String turfId) {
    if (_socket == null || !_socket!.connected) return;
    log('Joining turf room: $turfId');
    _socket!.emit('join:turf', {'turfId': turfId});
  }

  void leaveTurfRoom(String turfId) {
    if (_socket == null || !_socket!.connected) return;
    log('Leaving turf room: $turfId');
    _socket!.emit('leave:turf', {'turfId': turfId});
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
