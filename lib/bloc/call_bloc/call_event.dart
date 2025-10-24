part of 'call_bloc.dart';

abstract class CallEvent extends Equatable {
  const CallEvent();

  @override
  List<Object?> get props => [];
}

class ToggleMicRequested extends CallEvent {}

class RightAwayCallRequested extends CallEvent {}

class CreateCallRequested extends CallEvent {}

class JoinCallRequested extends CallEvent {
  final String roomId;
  final Map<String, dynamic>? room;

  const JoinCallRequested(this.roomId,this.room);

  @override
  List<Object?> get props => [roomId,room];
}

class QualityTicked extends CallEvent {
  final ConnectionQuality quality;

  const QualityTicked(this.quality);

  @override
  List<Object?> get props => [quality];
}

class JoinFromRoomAsOwner extends CallEvent {
  final String roomId;

  const JoinFromRoomAsOwner(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

class RequestToJoin extends CallEvent {
  final String roomId;

  const RequestToJoin(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

class HangUpRequested extends CallEvent {}

class ToggleCameraRequested extends CallEvent {}

class RemoteRoomDeleted extends CallEvent {
  const RemoteRoomDeleted();
}

class RefreshUIRequested extends CallEvent {
  const RefreshUIRequested();
}
