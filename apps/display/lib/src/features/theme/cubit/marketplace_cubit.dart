import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'marketplace_state.dart';

/// Manages the marketplace theme listing and per-user ownership state.
class MarketplaceCubit extends Cubit<MarketplaceState> {
  MarketplaceCubit(this._repository) : super(const MarketplaceInitial());

  final MarketplaceRepository _repository;

  /// Loads all marketplace themes (including ownership flags).
  Future<void> loadMarketplace() async {
    emit(const MarketplaceLoading());
    try {
      final themes = await _repository.listMarketplaceThemes();
      emit(MarketplaceLoaded(themes: themes));
    } catch (e) {
      emit(MarketplaceError(e.toString()));
    }
  }

  /// Re-fetches owned themes and updates the [isOwned] flag on each entry.
  ///
  /// Called after a purchase completes to reflect the new ownership without
  /// reloading the full marketplace list.
  Future<void> refreshOwnedThemes() async {
    final current = state;
    if (current is! MarketplaceLoaded) return;
    try {
      final owned = await _repository.getOwnedThemes();
      final ownedIds = owned.map((t) => t.theme.id).toSet();
      final updated = current.themes
          .map((t) => MarketplaceThemeInfo(
                theme: t.theme,
                priceUsd: t.priceUsd,
                stripeProductId: t.stripeProductId,
                isOwned: ownedIds.contains(t.theme.id),
              ))
          .toList();
      emit(MarketplaceLoaded(themes: updated));
    } catch (_) {
      // Ownership refresh is best-effort — don't emit error.
    }
  }
}
