import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../bloc/call_bloc/call_bloc.dart';


class WebRtcRepository {
  RTCPeerConnection? pc;
  late RTCVideoRenderer local ;
  late RTCVideoRenderer remote ;
  bool _renderersReady = false;


  static const _iceServers = {
    'iceServers': [
      {'urls': ['stun:stun.l.google.com:19302']},
    ],
  };


  final _pcConstraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };


  Future<void> initRenderers() async {
    if (_renderersReady) return;
    local = RTCVideoRenderer();
    remote = RTCVideoRenderer();
    await local.initialize();
    await remote.initialize();
    _renderersReady = true;
  }

  Future<void> resetRenderers() async {
    // dispose old ones if they exist
    if (_renderersReady) {
      try { await local.dispose(); } catch (_) {}
      try { await remote.dispose(); } catch (_) {}
      _renderersReady = false;
    }
    await initRenderers();
  }


  Future<MediaStream> openUserMedia() async {
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'}
    });
    local.srcObject = stream;
    return stream;
  }


  Future<void> createPeer(MediaStream localStream, {Function(MediaStream)? onRemote}) async {
    pc = await createPeerConnection(_iceServers, _pcConstraints);


    for (final track in localStream.getTracks()) {
      await pc!.addTrack(track, localStream);
    }


    pc!.onTrack = (RTCTrackEvent e) {
      if (e.streams.isNotEmpty) {
        remote.srcObject = e.streams[0];
        onRemote?.call(e.streams[0]);
      }
    };
  }


  Future<RTCSessionDescription> createOffer() async {
    final offer = await pc!.createOffer({'offerToReceiveAudio': 1, 'offerToReceiveVideo': 1});
    await pc!.setLocalDescription(offer);
    return offer;
  }


  Future<RTCSessionDescription> createAnswer() async {
    final answer = await pc!.createAnswer({'offerToReceiveAudio': 1, 'offerToReceiveVideo': 1});
    await pc!.setLocalDescription(answer);
    return answer;
  }


  Future<void> setRemote(RTCSessionDescription sdp) async {
    await pc!.setRemoteDescription(sdp);
  }

  void onIceCandidate(void Function(RTCIceCandidate) handler) {
    pc!.onIceCandidate = handler;
  }


  Future<void> addIce(RTCIceCandidate c) async => pc!.addCandidate(c);


  Future<void> hangUp() async {
    try {
      local.srcObject?.getTracks().forEach((t) => t.stop());
      remote.srcObject?.getTracks().forEach((t) => t.stop());
      local.srcObject = null;
      remote.srcObject = null;
      await pc?.close();
      pc = null;
    } finally {
      await resetRenderers();
    }
  }

  Future<ConnectionQuality> assessQuality() async {
    if (pc == null) return ConnectionQuality.bad;
    final reports = await pc!.getStats();

    double rttMs = 0, jitterMs = 0;
    bool sawVideoInbound = false, sawAudioInbound = false;

    for (final r in reports) {
      final type = r.type;
      final v = r.values;

      if (type == 'candidate-pair') {
        final nominated = v['nominated'] == true || v['selected'] == true;
        if (v['state'] == 'succeeded' && nominated) {
          final rtt = (v['currentRoundTripTime'] ?? v['roundTripTime']);
          if (rtt is num) rttMs = rtt * 1000.0;
        }
      }

      if (type == 'inbound-rtp' && v['kind'] == 'video') {
        sawVideoInbound = true;
        final j = v['jitter'];
        if (j is num) jitterMs = j * 1000.0;
      }
    }

    if (!sawVideoInbound) {
      for (final r in reports) {
        final v = r.values;
        if (r.type == 'inbound-rtp' && v['kind'] == 'audio') {
          sawAudioInbound = true;
          final j = v['jitter'];
          if (j is num) jitterMs = j * 1000.0;
          break;
        }
      }
    }

    if (!sawVideoInbound && !sawAudioInbound) {
      for (final r in reports) {
        final v = r.values;
        if (r.type == 'remote-inbound-rtp') {
          final j = v['jitter'];
          if (j is num) jitterMs = j * 1000.0;
          final rrtt = v['roundTripTime'];
          if (rrtt is num && rttMs == 0) rttMs = rrtt * 1000.0;
        }
      }
    }

    if (rttMs > 400 || jitterMs > 60) return ConnectionQuality.bad;
    if (rttMs > 250 || jitterMs > 35) return ConnectionQuality.poor;
    if (rttMs > 150 || jitterMs > 20) return ConnectionQuality.fair;
    return ConnectionQuality.excellent;
  }


}