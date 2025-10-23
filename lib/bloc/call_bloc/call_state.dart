part of 'call_bloc.dart';

enum ConnectionQuality { excellent, good, fair, poor, bad }

abstract class CallState extends Equatable {
  const CallState();

  @override
  List<Object?> get props => [];
}

class CallIdle extends CallState {}

class LoadingCallLive extends CallState {}

class LoadingDoneCallLive extends CallState {}

class CreatingCall extends CallState {
  final String roomId;

  const CreatingCall(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

class WaitingPeer extends CallState {
  final String roomId;

  const WaitingPeer(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

class InCall extends CallState {
  final String roomId;
  final RTCVideoRenderer local;
  final RTCVideoRenderer remote;
  final bool micEnabled;
  final ConnectionQuality quality;
  final bool frontCamera;

  const InCall({
    required this.roomId,
    required this.local,
    required this.remote,
    this.micEnabled = true,
    this.quality = ConnectionQuality.good,
    this.frontCamera = true,
  });

  InCall copyWith({
    bool? micEnabled,
    ConnectionQuality? quality,
    bool? frontCamera,
  }) => InCall(
    roomId: roomId,
    local: local,
    remote: remote,
    micEnabled: micEnabled ?? this.micEnabled,
    quality: quality ?? this.quality,
    frontCamera: frontCamera ?? this.frontCamera,
  );

  @override
  List<Object?> get props => [
    roomId,
    local,
    remote,
    micEnabled,
    quality,
    frontCamera,
  ];

  @override
  String toString() =>
      'CallState quantity: $quality, micEnable: $micEnabled, frontCamera:$frontCamera';
}

class CallEnded extends CallState {}

class CallError extends CallState {
  final String message;

  const CallError(this.message);

  @override
  List<Object?> get props => [message];
}

class CallDeleted extends CallState {}
