import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

import '../generated/theme/theme_validation_error.dart';

/// Result of validating a theme YAML/JSON document.
class ThemeValidationResult {
  const ThemeValidationResult({
    required this.isValid,
    required this.errors,
    this.resolvedTokens,
  });

  final bool isValid;
  final List<ThemeValidationError> errors;

  /// The fully resolved flat token map (with derived values filled in).
  /// Only populated when [isValid] is true.
  final Map<String, dynamic>? resolvedTokens;
}

/// Validates a raw theme YAML/JSON string against ThemeSchema v1.0.
///
/// Call [validate] to get a [ThemeValidationResult]. On success,
/// [ThemeValidationResult.resolvedTokens] contains the full flat token map
/// ready to store in [LandfallTheme.resolvedJson].
class ThemeValidator {
  // Defaults applied when tokens are absent.
  static const _defaults = <String, dynamic>{
    'surface.background.type': 'solid',
    'surface.background.value': '#0D0D0F',
    'surface.card.fill': 'rgba(255,255,255,0.05)',
    'surface.card.border.color': 'rgba(255,255,255,0.1)',
    'surface.card.border.width': 1.0,
    'surface.card.border.style': 'solid',
    'surface.card.radius': 8,
    'surface.card.blur': 0,
    'surface.card.shadow': 'none',
    'typography.fontFamily': 'System',
    'typography.scale': 'comfortable',
    'typography.heading.weight': 600,
    'typography.body.weight': 400,
    'typography.letterSpacing': 'normal',
    'typography.timeDisplay.fontFamily': 'System',
    'typography.timeDisplay.weight': 200,
    'color.accent': '#4A9EFF',
    'color.text.primary': '#FFFFFF',
    'color.text.secondary': 'rgba(255,255,255,0.6)',
    'color.text.tertiary': 'rgba(255,255,255,0.35)',
    'color.success': '#34C759',
    'color.warning': '#FF9F0A',
    'color.alert': '#FF3B30',
    'animation.transition': 'fade',
    'animation.speed': 'normal',
    'animation.cardEntry': 'fade',
    'animation.tickerScroll': 'normal',
    'moods.urgent.borderColor': 'rgba(255,59,48,0.8)',
    'moods.urgent.fillColor': 'rgba(255,59,48,0.1)',
    'moods.urgent.pulse': true,
    'moods.urgent.scale': 1.01,
    'moods.urgent.animation': 'pulse',
    'moods.celebratory.borderColor': 'rgba(52,199,89,0.6)',
    'moods.celebratory.fillColor': 'rgba(52,199,89,0.08)',
    'moods.celebratory.pulse': false,
    'moods.celebratory.scale': 1.0,
    'moods.celebratory.animation': 'glow',
    'moods.success.borderColor': 'rgba(52,199,89,0.5)',
    'moods.success.fillColor': 'rgba(52,199,89,0.06)',
    'moods.success.pulse': false,
    'moods.success.scale': 1.0,
    'moods.success.animation': 'none',
    'moods.muted.borderColor': 'rgba(255,255,255,0.1)',
    'moods.muted.fillColor': 'rgba(255,255,255,0.05)',
    'moods.muted.pulse': false,
    'moods.muted.scale': 1.0,
    'moods.muted.animation': 'none',
    'moods.muted.opacity': 0.5,
  };

  /// All keys that must appear in a fully resolved token map.
  static const requiredResolvedKeys = [
    'surface.background.type',
    'surface.background.value',
    'surface.card.fill',
    'surface.card.border.color',
    'surface.card.border.width',
    'surface.card.border.style',
    'surface.card.radius',
    'surface.card.blur',
    'surface.card.shadow',
    'typography.fontFamily',
    'typography.scale',
    'typography.heading.weight',
    'typography.body.weight',
    'typography.letterSpacing',
    'typography.timeDisplay.fontFamily',
    'typography.timeDisplay.weight',
    'color.accent',
    'color.accentMuted',
    'color.text.primary',
    'color.text.secondary',
    'color.text.tertiary',
    'color.divider',
    'color.agent.border',
    'color.success',
    'color.warning',
    'color.alert',
    'animation.transition',
    'animation.speed',
    'animation.cardEntry',
    'animation.tickerScroll',
    'moods.urgent.borderColor',
    'moods.urgent.fillColor',
    'moods.urgent.pulse',
    'moods.urgent.scale',
    'moods.urgent.animation',
    'moods.celebratory.borderColor',
    'moods.celebratory.fillColor',
    'moods.celebratory.pulse',
    'moods.celebratory.scale',
    'moods.celebratory.animation',
    'moods.success.borderColor',
    'moods.success.fillColor',
    'moods.success.pulse',
    'moods.success.scale',
    'moods.success.animation',
    'moods.muted.borderColor',
    'moods.muted.fillColor',
    'moods.muted.pulse',
    'moods.muted.scale',
    'moods.muted.animation',
    'moods.muted.opacity',
  ];

  static const _validBackgroundTypes = {'solid', 'gradient', 'image', 'blur'};
  static const _validBorderStyles = {'solid', 'dashed', 'none'};
  static const _validShadows = {'none', 'subtle', 'medium', 'strong'};
  static const _validTypographyScales = {'compact', 'comfortable', 'display'};
  static const _validLetterSpacings = {'tight', 'normal', 'wide'};
  static const _validTransitions = {'instant', 'fade', 'slide', 'scale'};
  static const _validSpeeds = {'fast', 'normal', 'relaxed'};
  static const _validCardEntries = {'fade', 'slide', 'scale', 'none'};
  static const _validTickerScrolls = {'slow', 'normal', 'fast'};
  static const _validUrgentAnimations = {'pulse', 'none'};
  static const _validCelebratoryAnimations = {
    'glow', 'confetti', 'scale', 'none'
  };

  static final _hexRe = RegExp(r'^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$');
  static final _rgbaRe = RegExp(
    r'^rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([0-9]*\.?[0-9]+)\s*\)$',
  );

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  static ThemeValidationResult validate(String yamlOrJson) {
    final errors = <ThemeValidationError>[];

    // Parse YAML / JSON.
    Map<String, dynamic> raw;
    try {
      final parsed = loadYaml(yamlOrJson);
      raw = _yamlToMap(parsed);
    } catch (_) {
      errors.add(ThemeValidationError(
        tokenPath: 'document',
        message: 'Could not parse as YAML or JSON.',
      ));
      return ThemeValidationResult(isValid: false, errors: errors);
    }

    // Version.
    final version = raw['version'];
    if (version == null) {
      errors.add(ThemeValidationError(
        tokenPath: 'version',
        message: 'version is required.',
      ));
    } else if (version != '1.0') {
      errors.add(ThemeValidationError(
        tokenPath: 'version',
        message: 'version must be exactly "1.0". Got: "$version".',
      ));
    }

    // meta.name
    final meta = raw['meta'] as Map<String, dynamic>?;
    final metaName = meta?['name'];
    if (metaName == null || (metaName is String && metaName.trim().isEmpty)) {
      errors.add(ThemeValidationError(
        tokenPath: 'meta.name',
        message: 'meta.name is required.',
      ));
    } else if (metaName is String && metaName.length > 60) {
      errors.add(ThemeValidationError(
        tokenPath: 'meta.name',
        message: 'meta.name must be at most 60 characters.',
      ));
    }

    // meta.description (optional)
    final metaDesc = meta?['description'];
    if (metaDesc is String && metaDesc.length > 200) {
      errors.add(ThemeValidationError(
        tokenPath: 'meta.description',
        message: 'meta.description must be at most 200 characters.',
      ));
    }

    // surface
    final surface = raw['surface'] as Map<String, dynamic>?;
    if (surface != null) {
      _validateSurface(surface, errors);
    }

    // typography
    final typography = raw['typography'] as Map<String, dynamic>?;
    if (typography != null) {
      _validateTypography(typography, errors);
    }

    // color
    final color = raw['color'] as Map<String, dynamic>?;
    if (color != null) {
      _validateColor(color, errors);
    }

    // animation
    final animation = raw['animation'] as Map<String, dynamic>?;
    if (animation != null) {
      _validateAnimation(animation, errors);
    }

    // moods
    final moods = raw['moods'] as Map<String, dynamic>?;
    if (moods != null) {
      _validateMoods(moods, errors);
    }

    if (errors.isNotEmpty) {
      return ThemeValidationResult(isValid: false, errors: errors);
    }

    final resolved = _resolve(raw);
    return ThemeValidationResult(
      isValid: true,
      errors: const [],
      resolvedTokens: resolved,
    );
  }

  // ---------------------------------------------------------------------------
  // Section validators
  // ---------------------------------------------------------------------------

  static void _validateSurface(
    Map<String, dynamic> s,
    List<ThemeValidationError> errors,
  ) {
    final bg = s['background'] as Map<String, dynamic>?;
    if (bg != null) {
      _validateEnum('surface.background.type', bg['type'],
          _validBackgroundTypes, errors, optional: true);
    }

    final card = s['card'] as Map<String, dynamic>?;
    if (card != null) {
      if (card['fill'] != null) {
        _validateRgba('surface.card.fill', card['fill'], errors);
      }
      final border = card['border'] as Map<String, dynamic>?;
      if (border != null) {
        if (border['color'] != null) {
          _validateRgba('surface.card.border.color', border['color'], errors);
        }
        if (border['width'] != null) {
          _validateFloatRange(
              'surface.card.border.width', border['width'], 0.0, 3.0, errors);
        }
        _validateEnum('surface.card.border.style', border['style'],
            _validBorderStyles, errors, optional: true);
      }
      if (card['radius'] != null) {
        _validateIntRange('surface.card.radius', card['radius'], 0, 24, errors);
      }
      if (card['blur'] != null) {
        _validateIntRange('surface.card.blur', card['blur'], 0, 20, errors);
      }
      _validateEnum(
          'surface.card.shadow', card['shadow'], _validShadows, errors,
          optional: true);
    }
  }

  static void _validateTypography(
    Map<String, dynamic> t,
    List<ThemeValidationError> errors,
  ) {
    _validateEnum('typography.scale', t['scale'], _validTypographyScales,
        errors, optional: true);
    _validateEnum('typography.letterSpacing', t['letterSpacing'],
        _validLetterSpacings, errors, optional: true);

    final heading = t['heading'] as Map<String, dynamic>?;
    if (heading?['weight'] != null) {
      _validateWeightRange(
          'typography.heading.weight', heading!['weight'], 300, 800, errors);
    }
    final body = t['body'] as Map<String, dynamic>?;
    if (body?['weight'] != null) {
      _validateWeightRange(
          'typography.body.weight', body!['weight'], 300, 600, errors);
    }
    final timeDisplay = t['timeDisplay'] as Map<String, dynamic>?;
    if (timeDisplay?['weight'] != null) {
      _validateWeightRange('typography.timeDisplay.weight',
          timeDisplay!['weight'], 100, 900, errors);
    }
  }

  static void _validateColor(
    Map<String, dynamic> c,
    List<ThemeValidationError> errors,
  ) {
    if (c['accent'] != null) _validateHex('color.accent', c['accent'], errors);
    if (c['accentMuted'] != null) {
      _validateRgba('color.accentMuted', c['accentMuted'], errors);
    }
    if (c['success'] != null) {
      _validateHex('color.success', c['success'], errors);
    }
    if (c['warning'] != null) {
      _validateHex('color.warning', c['warning'], errors);
    }
    if (c['alert'] != null) _validateHex('color.alert', c['alert'], errors);

    final text = c['text'] as Map<String, dynamic>?;
    if (text != null) {
      if (text['primary'] != null) {
        _validateHex('color.text.primary', text['primary'], errors);
      }
      if (text['secondary'] != null) {
        _validateRgba('color.text.secondary', text['secondary'], errors);
      }
      if (text['tertiary'] != null) {
        _validateRgba('color.text.tertiary', text['tertiary'], errors);
      }
    }

    final divider = c['divider'];
    if (divider != null) _validateRgba('color.divider', divider, errors);

    final agent = c['agent'] as Map<String, dynamic>?;
    if (agent?['border'] != null) {
      _validateRgba('color.agent.border', agent!['border'], errors);
    }
  }

  static void _validateAnimation(
    Map<String, dynamic> a,
    List<ThemeValidationError> errors,
  ) {
    _validateEnum(
        'animation.transition', a['transition'], _validTransitions, errors,
        optional: true);
    _validateEnum('animation.speed', a['speed'], _validSpeeds, errors,
        optional: true);
    _validateEnum(
        'animation.cardEntry', a['cardEntry'], _validCardEntries, errors,
        optional: true);
    _validateEnum('animation.tickerScroll', a['tickerScroll'],
        _validTickerScrolls, errors, optional: true);
  }

  static void _validateMoods(
    Map<String, dynamic> m,
    List<ThemeValidationError> errors,
  ) {
    final urgent = m['urgent'] as Map<String, dynamic>?;
    if (urgent != null) {
      if (urgent['borderColor'] != null) {
        _validateRgba('moods.urgent.borderColor', urgent['borderColor'], errors);
      }
      if (urgent['fillColor'] != null) {
        _validateRgba('moods.urgent.fillColor', urgent['fillColor'], errors);
      }
      if (urgent['scale'] != null) {
        _validateFloatRange(
            'moods.urgent.scale', urgent['scale'], 0.95, 1.10, errors);
      }
      _validateEnum('moods.urgent.animation', urgent['animation'],
          _validUrgentAnimations, errors, optional: true);
    }

    final celebratory = m['celebratory'] as Map<String, dynamic>?;
    if (celebratory != null) {
      if (celebratory['borderColor'] != null) {
        _validateRgba('moods.celebratory.borderColor',
            celebratory['borderColor'], errors);
      }
      if (celebratory['fillColor'] != null) {
        _validateRgba(
            'moods.celebratory.fillColor', celebratory['fillColor'], errors);
      }
      if (celebratory['scale'] != null) {
        _validateFloatRange('moods.celebratory.scale', celebratory['scale'],
            0.95, 1.10, errors);
      }
      _validateEnum(
          'moods.celebratory.animation',
          celebratory['animation'],
          _validCelebratoryAnimations,
          errors,
          optional: true);
    }

    final success = m['success'] as Map<String, dynamic>?;
    if (success != null) {
      if (success['borderColor'] != null) {
        _validateRgba(
            'moods.success.borderColor', success['borderColor'], errors);
      }
      if (success['fillColor'] != null) {
        _validateRgba('moods.success.fillColor', success['fillColor'], errors);
      }
      if (success['scale'] != null) {
        _validateFloatRange(
            'moods.success.scale', success['scale'], 0.95, 1.10, errors);
      }
    }

    final muted = m['muted'] as Map<String, dynamic>?;
    if (muted != null) {
      if (muted['borderColor'] != null) {
        _validateRgba('moods.muted.borderColor', muted['borderColor'], errors);
      }
      if (muted['fillColor'] != null) {
        _validateRgba('moods.muted.fillColor', muted['fillColor'], errors);
      }
      if (muted['opacity'] != null) {
        _validateFloatRange(
            'moods.muted.opacity', muted['opacity'], 0.3, 0.8, errors);
      }
      if (muted['scale'] != null) {
        _validateFloatRange(
            'moods.muted.scale', muted['scale'], 0.95, 1.10, errors);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Token resolution (defaults + derivation)
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _resolve(Map<String, dynamic> raw) {
    final m = <String, dynamic>{};

    // Start with schema defaults.
    m.addAll(_defaults);

    // Overlay parsed values.
    void overlay(String key, dynamic value) {
      if (value != null) m[key] = value;
    }

    final surface = raw['surface'] as Map<String, dynamic>?;
    final bg = surface?['background'] as Map<String, dynamic>?;
    overlay('surface.background.type', bg?['type']);
    overlay('surface.background.value', bg?['value']);
    if (bg?['overlay'] != null) {
      m['surface.background.overlay'] = bg!['overlay'];
    }

    final card = surface?['card'] as Map<String, dynamic>?;
    final border = card?['border'] as Map<String, dynamic>?;
    overlay('surface.card.fill', card?['fill']);
    overlay('surface.card.border.color', border?['color']);
    overlay('surface.card.border.width', _toDouble(border?['width']));
    overlay('surface.card.border.style', border?['style']);
    overlay('surface.card.radius', card?['radius']);
    overlay('surface.card.blur', card?['blur']);
    overlay('surface.card.shadow', card?['shadow']);

    final typo = raw['typography'] as Map<String, dynamic>?;
    overlay('typography.fontFamily', typo?['fontFamily']);
    overlay('typography.scale', typo?['scale']);
    overlay('typography.letterSpacing', typo?['letterSpacing']);
    final heading = typo?['heading'] as Map<String, dynamic>?;
    overlay('typography.heading.weight', heading?['weight']);
    final body = typo?['body'] as Map<String, dynamic>?;
    overlay('typography.body.weight', body?['weight']);
    final td = typo?['timeDisplay'] as Map<String, dynamic>?;
    overlay('typography.timeDisplay.fontFamily',
        td?['fontFamily'] ?? typo?['fontFamily']);
    overlay('typography.timeDisplay.weight', td?['weight']);

    final color = raw['color'] as Map<String, dynamic>?;
    overlay('color.accent', color?['accent']);
    overlay('color.success', color?['success']);
    overlay('color.warning', color?['warning']);
    overlay('color.alert', color?['alert']);
    final text = color?['text'] as Map<String, dynamic>?;
    overlay('color.text.primary', text?['primary']);
    overlay('color.text.secondary', text?['secondary']);
    overlay('color.text.tertiary', text?['tertiary']);

    // Derived values — computed after overlays so overrides are respected.
    if (color?['accentMuted'] != null) {
      m['color.accentMuted'] = color!['accentMuted'];
    } else {
      m['color.accentMuted'] = _hexToRgba(m['color.accent'] as String, 0.2);
    }
    if (color?['divider'] != null) {
      m['color.divider'] = color!['divider'];
    } else {
      m['color.divider'] = _hexToRgba(m['color.text.primary'] as String, 0.1);
    }
    final agent = color?['agent'] as Map<String, dynamic>?;
    if (agent?['border'] != null) {
      m['color.agent.border'] = agent!['border'];
    } else {
      m['color.agent.border'] =
          _hexToRgba(m['color.accent'] as String, 0.3);
    }

    final anim = raw['animation'] as Map<String, dynamic>?;
    overlay('animation.transition', anim?['transition']);
    overlay('animation.speed', anim?['speed']);
    overlay('animation.cardEntry', anim?['cardEntry']);
    overlay('animation.tickerScroll', anim?['tickerScroll']);

    final moods = raw['moods'] as Map<String, dynamic>?;
    _resolveMood(m, moods?['urgent'] as Map<String, dynamic>?, 'urgent',
        m['surface.card.border.color'] as String,
        m['surface.card.fill'] as String);
    _resolveMood(m, moods?['celebratory'] as Map<String, dynamic>?,
        'celebratory', m['surface.card.border.color'] as String,
        m['surface.card.fill'] as String);
    _resolveMood(m, moods?['success'] as Map<String, dynamic>?,
        'success', m['surface.card.border.color'] as String,
        m['surface.card.fill'] as String);
    _resolveMoodMuted(m, moods?['muted'] as Map<String, dynamic>?,
        m['surface.card.border.color'] as String,
        m['surface.card.fill'] as String);

    return m;
  }

  static void _resolveMood(
    Map<String, dynamic> m,
    Map<String, dynamic>? mood,
    String prefix,
    String defaultBorder,
    String defaultFill,
  ) {
    m['moods.$prefix.borderColor'] =
        mood?['borderColor'] ?? m['moods.$prefix.borderColor'] ?? defaultBorder;
    m['moods.$prefix.fillColor'] =
        mood?['fillColor'] ?? m['moods.$prefix.fillColor'] ?? defaultFill;
    m['moods.$prefix.pulse'] =
        mood?['pulse'] ?? m['moods.$prefix.pulse'] ?? false;
    m['moods.$prefix.scale'] =
        _toDouble(mood?['scale']) ?? (m['moods.$prefix.scale'] as num).toDouble();
    m['moods.$prefix.animation'] =
        mood?['animation'] ?? m['moods.$prefix.animation'] ?? 'none';
  }

  static void _resolveMoodMuted(
    Map<String, dynamic> m,
    Map<String, dynamic>? mood,
    String defaultBorder,
    String defaultFill,
  ) {
    _resolveMood(m, mood, 'muted', defaultBorder, defaultFill);
    m['moods.muted.opacity'] =
        _toDouble(mood?['opacity']) ?? (m['moods.muted.opacity'] as num).toDouble();
  }

  // ---------------------------------------------------------------------------
  // Primitive validators
  // ---------------------------------------------------------------------------

  static void _validateHex(
    String path,
    dynamic value,
    List<ThemeValidationError> errors,
  ) {
    if (value is! String || !_hexRe.hasMatch(value)) {
      errors.add(ThemeValidationError(
        tokenPath: path,
        message: '$path must be a 3 or 6-digit hex color (e.g. "#4A9EFF"). '
            'Got: "$value".',
      ));
    }
  }

  static void _validateRgba(
    String path,
    dynamic value,
    List<ThemeValidationError> errors,
  ) {
    if (value is! String) {
      errors.add(ThemeValidationError(
        tokenPath: path,
        message: '$path must be a string.',
      ));
      return;
    }
    // Also accept plain hex for rgba fields.
    if (_hexRe.hasMatch(value)) return;

    final m = _rgbaRe.firstMatch(value);
    if (m == null) {
      errors.add(ThemeValidationError(
        tokenPath: path,
        message:
            '$path must be rgba(r, g, b, a) with r/g/b in 0–255 and a in '
            '0.0–1.0. Got: "$value".',
      ));
      return;
    }
    final r = int.parse(m.group(1)!);
    final g = int.parse(m.group(2)!);
    final b = int.parse(m.group(3)!);
    final a = double.parse(m.group(4)!);
    if (r > 255 || g > 255 || b > 255) {
      errors.add(ThemeValidationError(
        tokenPath: path,
        message: '$path: r, g, b values must be in range 0–255.',
      ));
    }
    if (a < 0.0 || a > 1.0) {
      errors.add(ThemeValidationError(
        tokenPath: path,
        message: '$path: alpha must be in range 0.0–1.0. Got: $a.',
      ));
    }
  }

  static void _validateEnum(
    String path,
    dynamic value,
    Set<String> valid,
    List<ThemeValidationError> errors, {
    required bool optional,
  }) {
    if (value == null) {
      if (!optional) {
        errors.add(ThemeValidationError(
          tokenPath: path,
          message: '$path is required.',
        ));
      }
      return;
    }
    if (!valid.contains(value)) {
      errors.add(ThemeValidationError(
        tokenPath: path,
        message:
            '$path must be one of: ${valid.join(', ')}. Got: "$value".',
      ));
    }
  }

  static void _validateIntRange(
    String path,
    dynamic value,
    int min,
    int max,
    List<ThemeValidationError> errors,
  ) {
    if (value is! int) {
      errors.add(ThemeValidationError(
        tokenPath: path,
        message: '$path must be an integer.',
      ));
      return;
    }
    if (value < min || value > max) {
      errors.add(ThemeValidationError(
        tokenPath: path,
        message: '$path must be in range $min–$max. Got: $value.',
      ));
    }
  }

  static void _validateFloatRange(
    String path,
    dynamic value,
    double min,
    double max,
    List<ThemeValidationError> errors,
  ) {
    final v = _toDouble(value);
    if (v == null) {
      errors.add(ThemeValidationError(
        tokenPath: path,
        message: '$path must be a number.',
      ));
      return;
    }
    if (v < min || v > max) {
      errors.add(ThemeValidationError(
        tokenPath: path,
        message: '$path must be in range $min–$max. Got: $v.',
      ));
    }
  }

  static void _validateWeightRange(
    String path,
    dynamic value,
    int min,
    int max,
    List<ThemeValidationError> errors,
  ) {
    if (value is! int) {
      errors.add(ThemeValidationError(
        tokenPath: path,
        message: '$path must be an integer.',
      ));
      return;
    }
    if (value % 100 != 0) {
      errors.add(ThemeValidationError(
        tokenPath: path,
        message: '$path must be a multiple of 100. Got: $value.',
      ));
    } else if (value < min || value > max) {
      errors.add(ThemeValidationError(
        tokenPath: path,
        message: '$path must be in range $min–$max. Got: $value.',
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return null;
  }

  /// Converts a YAML value tree into a pure Dart [Map<String, dynamic>].
  static Map<String, dynamic> _yamlToMap(dynamic node) {
    if (node is YamlMap) {
      return {
        for (final entry in node.entries)
          entry.key.toString(): _yamlValue(entry.value),
      };
    }
    // Fall back to JSON if the yaml package returned something unexpected.
    final jsonStr = jsonEncode(node);
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  static dynamic _yamlValue(dynamic v) {
    if (v is YamlMap) return _yamlToMap(v);
    if (v is YamlList) return [for (final e in v) _yamlValue(e)];
    return v;
  }

  /// Converts a 6-digit hex color to an rgba string at the given alpha.
  static String _hexToRgba(String hex, double alpha) {
    final clean = hex.startsWith('#') ? hex.substring(1) : hex;
    String expanded;
    if (clean.length == 3) {
      expanded = clean.split('').map((c) => '$c$c').join();
    } else {
      expanded = clean;
    }
    final r = int.parse(expanded.substring(0, 2), radix: 16);
    final g = int.parse(expanded.substring(2, 4), radix: 16);
    final b = int.parse(expanded.substring(4, 6), radix: 16);
    return 'rgba($r,$g,$b,$alpha)';
  }

  /// Verifies the `sha256:` integrity field embedded in a theme YAML/JSON
  /// string. The field value must equal the SHA-256 of the raw content with
  /// the `sha256:` line itself stripped. (A08:2025)
  ///
  /// Returns `null` on success, or an error message string on failure.
  static String? verifySha256(String content) {
    String? embeddedHash;
    final stripped = <String>[];

    for (final line in content.split('\n')) {
      if (line.trimLeft().startsWith('sha256:')) {
        final afterColon =
            line.substring(line.indexOf('sha256:') + 'sha256:'.length).trim();
        embeddedHash = afterColon
            .replaceAll('"', '')
            .replaceAll("'", '')
            .trim();
      } else {
        stripped.add(line);
      }
    }

    if (embeddedHash == null || embeddedHash.isEmpty) {
      return 'Theme must include a sha256 integrity field. '
          'Compute SHA-256 of the file content without the sha256 line, '
          'then add sha256: <hex> to the file.';
    }

    final canonical = stripped.join('\n');
    final actual = sha256.convert(utf8.encode(canonical)).toString();

    if (actual != embeddedHash) {
      return 'Theme sha256 integrity check failed. '
          'The embedded sha256 does not match the computed hash of the content.';
    }

    return null;
  }
}
