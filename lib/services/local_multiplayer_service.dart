import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

enum MultiplayerMode { localSplitScreen, networkLAN }

enum ConnectionState { disconnected, hosting, connecting, connected }

class LocalMultiplayerService with ChangeNotifier {
  // Configuration réseau
  static const int defaultPort = 4040;
  static const String messageDelimiter = '|#|';
  static const Duration connectionTimeout = Duration(seconds: 5);

  // État du réseau
  ServerSocket? _server;
  Socket? _client;
  ConnectionState _state = ConnectionState.disconnected;
  String? _localIP;
  int _port = defaultPort;

  // Gestion des messages
  final StreamController<String> _messageStream = StreamController.broadcast();
  final List<String> _pendingMessages = [];
  Timer? _reconnectTimer;

  // Getters publics
  ConnectionState get state => _state;
  String? get localIP => _localIP;
  Stream<String> get messageStream => _messageStream.stream;

  /// Initialisation - Récupère l'IP locale
  Future<void> initialize() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            _localIP = addr.address;
            debugPrint('IP Locale détectée: $_localIP');
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur détection IP: $e');
    }
  }

  /// Héberge une partie en tant que serveur
  Future<bool> hostGame() async {
    if (_state != ConnectionState.disconnected) return false;

    try {
      _changeState(ConnectionState.hosting);
      _server = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        _port,
      ).timeout(connectionTimeout);

      _server!.listen(_handleNewConnection).onError((error, stackTrace) {
        _handleError('Erreur serveur: $error');
        return null;
      });

      debugPrint('🎮 Serveur hébergé sur $_localIP:$_port');
      return true;
    } catch (e) {
      _handleError('Échec hébergement: $e');
      return false;
    }
  }

  /// Rejoint une partie existante
  Future<bool> joinGame(String hostIP, {int? port}) async {
    if (_state != ConnectionState.disconnected) return false;

    try {
      _changeState(ConnectionState.connecting);
      _port = port ?? defaultPort;

      _client = await Socket.connect(hostIP, _port).timeout(connectionTimeout);

      _setupClientListeners();
      _changeState(ConnectionState.connected);
      debugPrint('✅ Connecté à $hostIP:$_port');
      return true;
    } catch (e) {
      _handleError('Échec connexion: $e');
      return false;
    }
  }

  /// Gestion des nouvelles connexions (côté serveur)
  void _handleNewConnection(Socket socket) {
    if (_client != null) {
      socket.destroy(); // Refuse les connexions multiples
      return;
    }

    _client = socket;
    _setupClientListeners();
    _changeState(ConnectionState.connected);
    debugPrint('👥 Client connecté: ${socket.remoteAddress.address}');
  }

  /// Configure les écouteurs du socket client
  void _setupClientListeners() {
    _client!.listen(
      (data) => _processIncomingData(data),
      onError: (error) => _handleError('Erreur socket: $error'),
      onDone: () => _handleDisconnection(),
    );

    // Envoie les messages en attente
    if (_pendingMessages.isNotEmpty) {
      for (var msg in _pendingMessages) {
        _client!.write('$msg$messageDelimiter');
      }
      _pendingMessages.clear();
    }
  }

  /// Traite les données reçues
  void _processIncomingData(Uint8List data) {
    try {
      final messages = utf8.decode(data).split(messageDelimiter);
      for (var msg in messages) {
        if (msg.trim().isNotEmpty) {
          _messageStream.add(msg);
          debugPrint('📩 Reçu: $msg');
        }
      }
    } catch (e) {
      _handleError('Erreur décodage: $e');
    }
  }

  /// Envoie un message au joueur connecté
  void sendMessage(String type, [String data = '']) {
    final message = '$type:$data';

    if (_client == null) {
      _pendingMessages.add(message);
      debugPrint('⏳ Message en attente: $message');
      return;
    }

    try {
      _client!.write('$message$messageDelimiter');
      debugPrint('📤 Envoyé: $message');
    } catch (e) {
      _handleError('Échec envoi: $e');
    }
  }

  /// Gère la déconnexion
  void _handleDisconnection() {
    debugPrint('⚠️ Déconnecté');
    _cleanUp();
    _changeState(ConnectionState.disconnected);
    _scheduleReconnect();
  }

  /// Nettoie les ressources
  void _cleanUp() {
    _client?.close();
    _server?.close();
    _client = null;
    _server = null;
  }

  /// Planifie une reconnexion automatique
  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;

    _reconnectTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_state == ConnectionState.disconnected && _client != null) {
        debugPrint('🔁 Tentative de reconnexion...');
        joinGame(_client!.remoteAddress.address);
      } else {
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
      }
    });
  }

  /// Gère les erreurs
  void _handleError(String message) {
    debugPrint('❌ $message');
    _cleanUp();
    _changeState(ConnectionState.disconnected);
  }

  /// Change l'état et notifie les listeners
  void _changeState(ConnectionState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Déconnecte proprement
  Future<void> disconnect() async {
    sendMessage('system', 'disconnect');
    await Future.delayed(const Duration(milliseconds: 100));
    _cleanUp();
    _changeState(ConnectionState.disconnected);
  }

  @override
  void dispose() {
    _messageStream.close();
    _reconnectTimer?.cancel();
    _cleanUp();
    super.dispose();
  }
}
