import 'package:landfall_shared/landfall_shared.dart';

sealed class CompanionState {}

class CompanionLoading extends CompanionState {}

class CompanionLoaded extends CompanionState {
  CompanionLoaded(this.entity);
  final CompanionEntity entity;
}

class CompanionError extends CompanionState {
  CompanionError(this.message);
  final String message;
}
