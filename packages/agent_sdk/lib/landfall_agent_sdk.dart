/// Official Dart SDK for pushing cards to a Landfall display.
///
/// ```dart
/// import 'package:landfall_agent_sdk/landfall_agent_sdk.dart';
///
/// final client = LandfallClient(
///   serverUrl: 'https://my.landfall.dev',
///   apiKey: 'lf_...',
/// );
///
/// await client.push(
///   CardDraft.build()
///     .title('Flight DEN→LAX dropped to \$287')
///     .priority(CardPriority.ephemeral)
///     .expires(const Duration(hours: 4)),
/// );
///
/// client.close();
/// ```
library;

export 'src/card_action.dart';
export 'src/card_draft.dart';
export 'src/card_layout.dart';
export 'src/card_priority.dart';
export 'src/landfall_client.dart';
export 'src/landfall_exception.dart';
export 'src/pushed_card.dart';
