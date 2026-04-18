import 'dart:convert';

import '../generated/protocol.dart';

const _validLayouts = {'small', 'medium', 'large', 'full'};
const _validPriorities = {'ephemeral', 'normal', 'persistent'};
const _maxTitleLength = 200;
const _maxBodyLength = 2000;
const _maxSourceLength = 100;
const _maxDataJsonLength = 32768; // 32 KB

/// Validates an agent-supplied [CardPushRequest].
///
/// Returns a list of human-readable error messages.
/// An empty list means the request is valid.
List<String> validateCardPushRequest(CardPushRequest request) {
  final errors = <String>[];

  // source
  if (request.source.trim().isEmpty) {
    errors.add('source must not be empty.');
  } else if (request.source.length > _maxSourceLength) {
    errors.add('source must be at most $_maxSourceLength characters.');
  } else if (!RegExp(r'^[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+$')
      .hasMatch(request.source)) {
    errors.add(
      'source must follow the format "<namespace>.<name>" '
      '(e.g. "agent.claude" or "skill.calendar"). '
      'Only letters, digits, underscores, and dots are allowed.',
    );
  }

  // title
  if (request.title.trim().isEmpty) {
    errors.add('title must not be empty.');
  } else if (request.title.length > _maxTitleLength) {
    errors.add('title must be at most $_maxTitleLength characters.');
  }

  // body (optional)
  if (request.body != null && request.body!.length > _maxBodyLength) {
    errors.add('body must be at most $_maxBodyLength characters.');
  }

  // layout (optional)
  if (request.layout != null && !_validLayouts.contains(request.layout)) {
    errors.add(
      'layout must be one of: ${_validLayouts.join(', ')}. '
      'Got: "${request.layout}".',
    );
  }

  // priority (optional)
  if (request.priority != null &&
      !_validPriorities.contains(request.priority)) {
    errors.add(
      'priority must be one of: ${_validPriorities.join(', ')}. '
      'Got: "${request.priority}".',
    );
  }

  // dataJson (optional) — must be a valid JSON object if provided
  if (request.dataJson != null) {
    if (request.dataJson!.length > _maxDataJsonLength) {
      errors.add('dataJson must be at most $_maxDataJsonLength bytes.');
    } else {
      try {
        final decoded = jsonDecode(request.dataJson!);
        if (decoded is! Map) {
          errors.add(
            'dataJson must be a JSON object ({}), not an array or scalar.',
          );
        }
      } on FormatException {
        errors.add('dataJson must be valid JSON.');
      }
    }
  }

  return errors;
}
