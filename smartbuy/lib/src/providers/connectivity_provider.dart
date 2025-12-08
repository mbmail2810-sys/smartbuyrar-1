import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<ConnectivityResult>(
    (ref) => Connectivity().onConnectivityChanged.map((event) => event.first));
