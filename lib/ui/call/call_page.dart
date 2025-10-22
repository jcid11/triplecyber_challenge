import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:triplecyber_challenge/ui/call/view/call_form.dart';

class CallPage extends StatelessWidget {
  final String roomId;
  final RTCVideoRenderer local;
  final RTCVideoRenderer remote;

  const CallPage({
    super.key,
    required this.roomId,
    required this.local,
    required this.remote,
  });

  @override
  Widget build(BuildContext context) => CallScreen(roomId: roomId, local: local, remote: remote,);
}
