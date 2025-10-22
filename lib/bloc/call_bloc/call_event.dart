part of 'call_bloc.dart';
abstract class CallEvent extends Equatable {
  const CallEvent();
  @override
  List<Object?> get props => [];
}

class ToggleMicRequested extends CallEvent {}


class RightAwayCallRequested extends CallEvent{}

class CreateCallRequested extends CallEvent {}


class JoinCallRequested extends CallEvent {
  final String roomId;
  const JoinCallRequested(this.roomId);
  @override
  List<Object?> get props => [roomId];
}

class QualityTicked extends CallEvent {
  final ConnectionQuality quality;
  const QualityTicked(this.quality);
  @override
  List<Object?> get props => [quality];
}


class HangUpRequested extends CallEvent {}