import 'dart:convert';

import '../generated/protocol.dart';

const _validLayouts = {'small', 'medium', 'large', 'full', 'ticker'};
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

  // ticker cards may not be persistent — their value is ephemerality
  if (request.layout == 'ticker' && request.persistent == true) {
    errors.add(
      'ticker cards may not be persistent. '
      'Use a normal layout for persistent content.',
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

  // actionsJson (optional) — validated array of action objects
  if (request.actionsJson != null) {
    const maxActionsJsonBytes = 8192;
    const maxActions = 5;
    const maxLabelLength = 80;
    const allowedTypes = {'dismiss', 'openUrl', 'webhook', 'openSettings'};
    const allowedSchemes = {'https', 'http'};

    if (request.actionsJson!.length > maxActionsJsonBytes) {
      errors.add('actionsJson must be at most $maxActionsJsonBytes bytes.');
    } else {
      try {
        final list = jsonDecode(request.actionsJson!);
        if (list is! List) {
          errors.add('actionsJson must be a JSON array.');
        } else {
          if (list.length > maxActions) {
            errors.add(
              'actionsJson must contain at most $maxActions actions.',
            );
          }
          for (final item in list) {
            if (item is! Map) {
              errors.add('Each action must be a JSON object.');
              break;
            }
            final type = item['type'] as String?;
            if (type == null || !allowedTypes.contains(type)) {
              errors.add(
                'action.type must be one of: ${allowedTypes.join(", ")}.',
              );
              break;
            }
            final label = item['label'] as String?;
            if (label == null || label.trim().isEmpty) {
              errors.add('action.label must not be empty.');
              break;
            }
            if (label.length > maxLabelLength) {
              errors.add(
                'action.label must be at most $maxLabelLength characters.',
              );
              break;
            }
            final payload = item['payload'] as String?;
            if (payload != null &&
                (type == 'openUrl' || type == 'webhook')) {
              final uri = Uri.tryParse(payload);
              if (uri == null || !allowedSchemes.contains(uri.scheme)) {
                errors.add(
                  'action.payload must be a valid https:// or http:// URL.',
                );
                break;
              }
            }
          }
        }
      } on FormatException {
        errors.add('actionsJson must be valid JSON.');
      }
    }
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
