part of 'call_bloc.dart';

enum ConnectionQuality { excellent, good, fair, poor, bad }

abstract class CallState extends Equatable {
  final bool micEnabled;
  const CallState({this.micEnabled = true});

  @override
  List<Object?> get props => [micEnabled];
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
  final ConnectionQuality quality;
  final bool frontCamera;

  const InCall({
    required this.roomId,
    required this.local,
    required this.remote,
    required super.micEnabled,
    this.quality = ConnectionQuality.good,
    this.frontCamera = true,
  }) ; // ✅ pass to parent

  InCall copyWith({
    bool? micEnabled,
    ConnectionQuality? quality,
    bool? frontCamera,
  }) {
    return InCall(
      roomId: roomId,
      local: local,
      remote: remote,
      micEnabled: micEnabled ?? this.micEnabled,
      quality: quality ?? this.quality,
      frontCamera: frontCamera ?? this.frontCamera,
    );
  }

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
      'InCall(quality: $quality, frontCamera: $frontCamera, micEnabled: $micEnabled)';
}


class CallEnded extends CallState {}

class CallError extends CallState {
  final String message;

  const CallError(this.message);

  @override
  List<Object?> get props => [message];
}

class CallDeleted extends CallState {}

class RefreshState extends CallState {
  const RefreshState({required super.micEnabled});
}

class CallDeletedByOwner extends CallState{}
