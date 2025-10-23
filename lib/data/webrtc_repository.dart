import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../bloc/call_bloc/call_bloc.dart';

class WebRtcRepository {
  RTCPeerConnection? pc;
  late RTCVideoRenderer local;

  late RTCVideoRenderer remote;

  bool _renderersReady = false;
  bool _usingFrontCamera = true;

  bool get isFrontCamera => _usingFrontCamera;

  static const _iceServers = {
    'iceServers': [
      {
        'urls': ['stun:stun.l.google.com:19302'],
      },
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
    _usingFrontCamera = true;
  }

  Future<void> resetRenderers() async {
    if (_renderersReady) {
      try {
        await local.dispose();
      } catch (_) {}
      try {
        await remote.dispose();
      } catch (_) {}
      _renderersReady = false;
    }
    await initRenderers();
  }

  Future<MediaStream> openUserMedia() async {
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'},
    });
    local.srcObject = stream;
    return stream;
  }

  Future<bool> toggleCamera() async {
    final tracks = local.srcObject?.getVideoTracks();
    if (tracks == null || tracks.isEmpty) return _usingFrontCamera;

    try {
      await Helper.switchCamera(tracks.first);
      _usingFrontCamera = !_usingFrontCamera;
      return _usingFrontCamera;
    } catch (e) {
      throw ('Error has occurred toggling camera :$e');
    }
  }

  Future<void> createPeer(
      MediaStream localStream, {
        void Function(MediaStream)? onRemote,
      }) async {
    pc = await createPeerConnection(_iceServers, _pcConstraints);

    for (final track in localStream.getTracks()) {
      await pc!.addTrack(track, localStream);
    }

    pc!.onAddStream = (MediaStream s) {
      remote.srcObject = s;
      onRemote?.call(s);
    };

    pc!.onTrack = (RTCTrackEvent e) async {
      if (e.streams.isNotEmpty) {
        final s = e.streams.first;
        remote.srcObject = s;
        onRemote?.call(s);
        return;
      }

      MediaStream target = remote.srcObject ?? await createLocalMediaStream('remote-ms');
      final alreadyHasVideo = target.getVideoTracks().isNotEmpty;
      final alreadyHasAudio = target.getAudioTracks().isNotEmpty;

      if (e.track.kind == 'video' && !alreadyHasVideo) {
        await target.addTrack(e.track);
        remote.srcObject = target;
        onRemote?.call(target);
      } else if (e.track.kind == 'audio' && !alreadyHasAudio) {
        await target.addTrack(e.track);
        remote.srcObject = target;
        onRemote?.call(target);
      }
    };
  }



  Future<RTCSessionDescription> createOffer() async {
    final offer = await pc!.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 1,
    });
    await pc!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer() async {
    final answer = await pc!.createAnswer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 1,
    });
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
