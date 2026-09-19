import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/supabase_provider.dart';

/// Whether the app currently has a live connection to the backend —
/// Stage 4 Part 7's minimal "offline banner" need. Reuses the Realtime
/// socket Part 1 already wired up (`client.realtime`) as the signal,
/// rather than adding a new connectivity-detection package: for a
/// Supabase-backed app, "is the Realtime socket open" is a more
/// relevant proxy for "can I actually reach my backend" than raw
/// device network status would be (a phone can have Wi-Fi and still
/// not reach Supabase, or vice versa on a captive portal).
///
/// Deliberately NOT `.autoDispose` — this needs to keep the socket
/// open and keep emitting for the whole app session regardless of
/// which screen is on top, the same lifetime `GoRouterRefreshStream`
/// already has.
final connectivityProvider = StreamProvider<bool>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final controller = StreamController<bool>.broadcast();

  controller.add(client.realtime.isConnected);
  client.realtime.onOpen(() => controller.add(true));
  client.realtime.onClose((_) => controller.add(false));
  client.realtime.onError((_) => controller.add(false));

  // Subscribing to a channel (even one with no listeners attached) is
  // what actually opens the socket — `RealtimeClient.connect()` itself
  // is package-internal, not part of the public API, so this is the
  // supported way to keep it alive for the app's whole session.
  final heartbeat = client.channel('connectivity-heartbeat');
  heartbeat.subscribe();

  ref.onDispose(() {
    controller.close();
    client.removeChannel(heartbeat);
  });
  return controller.stream;
});
