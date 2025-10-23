import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';
import '../../data/signaling_repository.dart';
import '../../data/webrtc_repository.dart';

part 'call_event.dart';

part 'call_state.dart';

class CallBloc extends Bloc<CallEvent, CallState> {
  final SignalingRepository signaling;
  final WebRtcRepository webrtc;

  StreamSubscription? _roomSub;
  StreamSubscription? _callerIceSub;
  StreamSubscription? _calleeIceSub;

  String? _roomId;
  MediaStream? _localStream;
  bool _isRoomOwner = false;

  Timer? _qualityTimer;

  CallBloc({required this.signaling, required this.webrtc})
    : super(CallIdle()) {
    on<CreateCallRequested>(_onCreateCall);
    on<JoinCallRequested>(_onJoinCall);
    on<HangUpRequested>(_onHangUp);
    on<QualityTicked>(_onQualityTicked);
    on<RightAwayCallRequested>(_rightAwayCallCreated);
    on<ToggleMicRequested>(_onToggleMic);
    on<ToggleCameraRequested>(_onToggleCamera);
    on<RemoteRoomDeleted>(_onRemoteRoomDeleted);
    on<RefreshUIRequested>(_onRefreshUIRequested);

  }


  void _onRefreshUIRequested(
      RefreshUIRequested e,
      Emitter<CallState> emit,
      ) {
    final current = state;
    emit( RefreshState());   // <- pulse only for listeners
    emit(current);                // <- restore previous state immediately
  }
  Future<void> _onToggleMic(
    ToggleMicRequested e,
    Emitter<CallState> emit,
  ) async {
    final track =
        _localStream?.getAudioTracks().isNotEmpty == true
            ? _localStream!.getAudioTracks().first
            : null;
    if (track == null) return;

    final newEnabled = !track.enabled;
    track.enabled = newEnabled;

    final s = state;
    if (s is InCall) {
      emit(s.copyWith(micEnabled: newEnabled));
    }
  }

  Future<void> _onToggleCamera(
    ToggleCameraRequested event,
    Emitter<CallState> emit,
  ) async {
    final isFront = await webrtc.toggleCamera();
    final s = state;
    if (s is InCall) {
      emit(s.copyWith(frontCamera: isFront));
    }
  }

  Future<void> _rightAwayCallCreated(
    RightAwayCallRequested event,
    Emitter<CallState> emit,
  ) async {
    emit(LoadingCallLive());
    try {
      _isRoomOwner = true;
      _roomId = const Uuid().v4().substring(0, 6).toUpperCase();

      await webrtc.initRenderers();
      _localStream = await webrtc.openUserMedia();
      await webrtc.createPeer(_localStream!);

      // Send caller ICE
      webrtc.onIceCandidate((c) {
        signaling.addCallerCandidate(_roomId!, {
          'candidate': c.candidate,
          'sdpMid': c.sdpMid,
          'sdpMLineIndex': c.sdpMLineIndex,
        });
      });

      final offer = await webrtc.createOffer();
      await signaling.createRoom(_roomId!, {
        'type': offer.type,
        'sdp': offer.sdp,
      });

      // Watch answer and set remote when it arrives
      _roomSub?.cancel();
      _roomSub = signaling.watchRoom(_roomId!).listen((snap) async {
        final data = snap.data();
        final ans = data?['answer'];
        if (ans != null  ) {
            await webrtc.setRemote(
              RTCSessionDescription(ans['sdp'], ans['type']),
            );
            add(const RefreshUIRequested());
        }
      });

      // Consume callee ICE
      _calleeIceSub?.cancel();
      _calleeIceSub = signaling.watchCalleeCandidates(_roomId!).listen((qs) {
        for (final ch in qs.docChanges) {
          if (ch.type == DocumentChangeType.added) {
            final c = ch.doc.data();
            webrtc.addIce(
              RTCIceCandidate(
                c?['candidate'],
                c?['sdpMid'],
                c?['sdpMLineIndex'],
              ),
            );
          }
        }
      });
      emit(LoadingDoneCallLive());
      emit(
        InCall(
          roomId: _roomId!,
          local: webrtc.local,
          remote: webrtc.remote,
          micEnabled: _initialMicEnabled,
          quality: ConnectionQuality.good,
          frontCamera: webrtc.isFrontCamera,
        ),
      );
      _startQualityPolling();
    } catch (e) {
      emit(CallError('Create failed: $e'));
    }
  }

  Future<void> _onCreateCall(
    CreateCallRequested event,
    Emitter<CallState> emit,
  ) async {
    try {
      _roomId = const Uuid().v4().substring(0, 6).toUpperCase();
      await webrtc.initRenderers();
      _localStream = await webrtc.openUserMedia();
      await webrtc.createPeer(_localStream!, onRemote: (_) {
      });

      // ICE out
      webrtc.onIceCandidate((c) {
        signaling.addCallerCandidate(_roomId!, {
          'candidate': c.candidate,
          'sdpMid': c.sdpMid,
          'sdpMLineIndex': c.sdpMLineIndex,
        });
      });

      final offer = await webrtc.createOffer();
      await signaling.createRoom(_roomId!, {
        'type': offer.type,
        'sdp': offer.sdp,
      });

      // Watch for answer
      _roomSub?.cancel();
      _roomSub = signaling.watchRoom(_roomId!).listen((snap) async {
        final data = snap.data();
        final ans = data?['answer'];
        if (ans != null &&
            webrtc.pc?.signalingState !=
                RTCSignalingState.RTCSignalingStateStable) {
          await webrtc.setRemote(
            RTCSessionDescription(ans['sdp'], ans['type']),
          );
          emit(
            InCall(
              roomId: _roomId!,
              local: webrtc.local,
              remote: webrtc.remote,
            ),
          );
        }
      });

      // Watch callee ICE
      _calleeIceSub?.cancel();
      _calleeIceSub = signaling.watchCalleeCandidates(_roomId!).listen((qs) {
        for (final ch in qs.docChanges) {
          if (ch.type == DocumentChangeType.added) {
            final c = ch.doc.data();
            webrtc.addIce(
              RTCIceCandidate(
                c?['candidate'],
                c?['sdpMid'],
                c?['sdpMLineIndex'],
              ),
            );
          }
        }
      });

      emit(WaitingPeer(_roomId!));
    } catch (e) {
      emit(CallError('Create failed: $e'));
    }
  }

  Future<void> _onJoinCall(
    JoinCallRequested event,
    Emitter<CallState> emit,
  ) async {
    try {
      _isRoomOwner = false;
      _roomId = event.roomId.trim();

      final room = await signaling.getRoom(_roomId!);
      if (room == null || room['offer'] == null) {
        emit(const CallError('Room not found or missing offer'));
        return;
      }

      await webrtc.initRenderers();
      _localStream = await webrtc.openUserMedia();
      await webrtc.createPeer(_localStream!, onRemote: (_) {});

      // Apply remote offer
      final offer = room['offer'];
      await webrtc.setRemote(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      // Send callee ICE
      webrtc.onIceCandidate((c) {
        signaling.addCalleeCandidate(_roomId!, {
          'candidate': c.candidate,
          'sdpMid': c.sdpMid,
          'sdpMLineIndex': c.sdpMLineIndex,
        });
      });

      // Create/Send answer
      final answer = await webrtc.createAnswer();
      await signaling.setAnswer(_roomId!, {
        'type': answer.type,
        'sdp': answer.sdp,
      });

      // Consume caller ICE
      _callerIceSub?.cancel();
      _callerIceSub = signaling.watchCallerCandidates(_roomId!).listen((qs) {
        for (final ch in qs.docChanges) {
          if (ch.type == DocumentChangeType.added) {
            final c = ch.doc.data();
            webrtc.addIce(
              RTCIceCandidate(
                c?['candidate'],
                c?['sdpMid'],
                c?['sdpMLineIndex'],
              ),
            );
          }
        }
      });
      // NEW: watch the room doc for deletion/ended
      _roomSub?.cancel();
      _roomSub = signaling.watchRoom(_roomId!).listen((snap) async {
        if (!snap.exists || (snap.data()?['ended'] == true)) {
          add(const RemoteRoomDeleted()); // -> triggers local teardown
          return;
        }
      });

      // Emit InCall and start quality polling
      emit(
        InCall(
          roomId: _roomId!,
          local: webrtc.local,
          remote: webrtc.remote,
          micEnabled: _initialMicEnabled,
          quality: ConnectionQuality.good,
          frontCamera: webrtc.isFrontCamera,
        ),
      );
      _startQualityPolling();
    } catch (e) {
      emit(CallError('Join failed: $e'));
    }
  }

  Future<void> _onRemoteRoomDeleted(
    RemoteRoomDeleted e,
    Emitter<CallState> emit,
  ) async {
    try {
      _stopQualityPolling();

      _roomSub?.cancel();
      _callerIceSub?.cancel();
      _calleeIceSub?.cancel();
      _roomSub = _callerIceSub = _calleeIceSub = null;

      await webrtc.hangUp();

      _roomId = null;
      _isRoomOwner = false;
      _localStream = null;

      emit(CallEnded());
      emit(CallIdle());
    } catch (err) {
      emit(CallError('Remote ended: $err'));
    }
  }

  Future<void> _onHangUp(HangUpRequested event, Emitter<CallState> emit) async {
    _stopQualityPolling();

    _roomSub?.cancel();
    _callerIceSub?.cancel();
    _calleeIceSub?.cancel();
    _roomSub = _callerIceSub = _calleeIceSub = null;

    await webrtc.hangUp();
    // 3) capture room ownership BEFORE clearing local fields
    final roomId = _roomId;
    final isOwner = _isRoomOwner;

    // 4) clear local session state (so UI can leave right away)
    _roomId = null;
    _isRoomOwner = false;
    _localStream = null;

    emit(CallEnded());
    emit(CallIdle());
    if (isOwner && roomId != null) {
      try {
        await signaling.deleteRoomDeep(roomId);
        emit(CallDeleted());
      } catch (e) {
        debugPrint('Room delete failed: $e');
      }
    }
  }

  Future<void> _onQualityTicked(
    QualityTicked e,
    Emitter<CallState> emit,
  ) async {
    final s = state;
    if (s is InCall && s.quality != e.quality) {
      emit(s.copyWith(quality: e.quality));
    }
  }

  bool get _initialMicEnabled {
    final tracks = _localStream?.getAudioTracks();
    return (tracks != null && tracks.isNotEmpty) ? tracks.first.enabled : true;
  }

  void _startQualityPolling() {
    _qualityTimer?.cancel();
    _qualityTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final q = await webrtc.assessQuality();
        add(QualityTicked(q));
      } catch (e, st) {
        debugPrint('assessQuality error: $e\n$st');
      }
    });
  }

  void _stopQualityPolling() {
    _qualityTimer?.cancel();
    _qualityTimer = null;
  }

  @override
  Future<void> close() {
    _stopQualityPolling();
    _roomSub?.cancel();
    _callerIceSub?.cancel();
    _calleeIceSub?.cancel();
    return super.close();
  }
}

