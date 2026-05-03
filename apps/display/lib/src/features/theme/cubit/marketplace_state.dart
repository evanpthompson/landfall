import 'package:landfall_shared/landfall_shared.dart';

sealed class MarketplaceState {
  const MarketplaceState();
}

final class MarketplaceInitial extends MarketplaceState {
  const MarketplaceInitial();
}

final class MarketplaceLoading extends MarketplaceState {
  const MarketplaceLoading();
}

final class MarketplaceLoaded extends MarketplaceState {
  const MarketplaceLoaded({this.themes = const []});

  final List<MarketplaceThemeInfo> themes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MarketplaceLoaded) return false;
    if (themes.length != other.themes.length) return false;
    for (var i = 0; i < themes.length; i++) {
      if (themes[i].theme.id != other.themes[i].theme.id ||
          themes[i].isOwned != other.themes[i].isOwned) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(
        themes.map((t) => Object.hash(t.theme.id, t.isOwned)),
      );
}

final class MarketplaceError extends MarketplaceState {
  const MarketplaceError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketplaceError && message == other.message;

  @override
  int get hashCode => message.hashCode;
}
