import 'package:landfall_shared/landfall_shared.dart';

sealed class CompanionState {}

class CompanionLoading extends CompanionState {}

class CompanionLoaded extends CompanionState {
  CompanionLoaded(this.entity, {this.companionBaseUrl = ''});
  final CompanionEntity entity;

  /// Server-reported base URL for the companion QR (e.g.
  /// `https://landfall.local`). Empty string when the server could not
  /// derive one — callers should fall back to their configured web URL.
  final String companionBaseUrl;
}

class CompanionError extends CompanionState {
  CompanionError(this.message);
  final String message;
}
