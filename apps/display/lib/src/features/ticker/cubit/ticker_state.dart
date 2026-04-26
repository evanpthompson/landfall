import 'package:landfall_shared/landfall_shared.dart';

sealed class TickerState {
  const TickerState();
}

/// No ticker messages are currently active.
final class TickerEmpty extends TickerState {
  const TickerEmpty();

  @override
  bool operator ==(Object other) => other is TickerEmpty;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// The ticker buffer has at least one active message.
final class TickerLoaded extends TickerState {
  const TickerLoaded(this.messages);

  /// Active ticker messages, newest first, max 10.
  final List<Card> messages;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TickerLoaded &&
          messages.length == other.messages.length &&
          List.generate(
            messages.length,
            (i) => messages[i] == other.messages[i],
          ).every((e) => e);

  @override
  int get hashCode => Object.hashAll(messages);
}
