/// Fully resolved token set for a Landfall theme.
///
/// All fields have concrete values — derived tokens are pre-computed on the
/// server before this object ever reaches the client. The renderer maps these
/// directly to widget styles with no further defaulting logic required.
class LandfallThemeTokens {
  const LandfallThemeTokens({
    required this.backgroundType,
    required this.backgroundValue,
    this.backgroundOverlay,
    required this.cardFill,
    required this.cardBorderColor,
    required this.cardBorderWidth,
    required this.cardBorderStyle,
    required this.cardRadius,
    required this.cardBlur,
    required this.cardShadow,
    required this.fontFamily,
    required this.typographyScale,
    required this.headingWeight,
    required this.bodyWeight,
    required this.letterSpacing,
    required this.timeDisplayFontFamily,
    required this.timeDisplayWeight,
    required this.colorAccent,
    required this.colorAccentMuted,
    required this.colorTextPrimary,
    required this.colorTextSecondary,
    required this.colorTextTertiary,
    required this.colorDivider,
    required this.colorAgentBorder,
    required this.colorSuccess,
    required this.colorWarning,
    required this.colorAlert,
    required this.animationTransition,
    required this.animationSpeed,
    required this.animationCardEntry,
    required this.animationTickerScroll,
    required this.moodUrgentBorderColor,
    required this.moodUrgentFillColor,
    required this.moodUrgentPulse,
    required this.moodUrgentScale,
    required this.moodUrgentAnimation,
    required this.moodCelebratoryBorderColor,
    required this.moodCelebratoryFillColor,
    required this.moodCelebratoryPulse,
    required this.moodCelebratoryScale,
    required this.moodCelebratoryAnimation,
    required this.moodSuccessBorderColor,
    required this.moodSuccessFillColor,
    required this.moodSuccessPulse,
    required this.moodSuccessScale,
    required this.moodSuccessAnimation,
    required this.moodMutedBorderColor,
    required this.moodMutedFillColor,
    required this.moodMutedPulse,
    required this.moodMutedScale,
    required this.moodMutedAnimation,
    required this.moodMutedOpacity,
  });

  // Surface — background
  final String backgroundType;
  final String backgroundValue;
  final String? backgroundOverlay;

  // Surface — card
  final String cardFill;
  final String cardBorderColor;
  final double cardBorderWidth;
  final String cardBorderStyle;
  final int cardRadius;
  final int cardBlur;
  final String cardShadow;

  // Typography
  final String fontFamily;
  final String typographyScale;
  final int headingWeight;
  final int bodyWeight;
  final String letterSpacing;
  final String timeDisplayFontFamily;
  final int timeDisplayWeight;

  // Color
  final String colorAccent;
  final String colorAccentMuted;
  final String colorTextPrimary;
  final String colorTextSecondary;
  final String colorTextTertiary;
  final String colorDivider;
  final String colorAgentBorder;
  final String colorSuccess;
  final String colorWarning;
  final String colorAlert;

  // Animation
  final String animationTransition;
  final String animationSpeed;
  final String animationCardEntry;
  final String animationTickerScroll;

  // Moods — urgent
  final String moodUrgentBorderColor;
  final String moodUrgentFillColor;
  final bool moodUrgentPulse;
  final double moodUrgentScale;
  final String moodUrgentAnimation;

  // Moods — celebratory
  final String moodCelebratoryBorderColor;
  final String moodCelebratoryFillColor;
  final bool moodCelebratoryPulse;
  final double moodCelebratoryScale;
  final String moodCelebratoryAnimation;

  // Moods — success
  final String moodSuccessBorderColor;
  final String moodSuccessFillColor;
  final bool moodSuccessPulse;
  final double moodSuccessScale;
  final String moodSuccessAnimation;

  // Moods — muted
  final String moodMutedBorderColor;
  final String moodMutedFillColor;
  final bool moodMutedPulse;
  final double moodMutedScale;
  final String moodMutedAnimation;
  final double moodMutedOpacity;

  /// Deserialises from the flat token map stored in [LandfallTheme.resolvedJson].
  factory LandfallThemeTokens.fromMap(Map<String, dynamic> m) {
    double d(String k) => (m[k] as num).toDouble();
    int i(String k) => (m[k] as num).toInt();
    String s(String k) => m[k] as String;
    bool b(String k) => m[k] as bool;

    return LandfallThemeTokens(
      backgroundType: s('surface.background.type'),
      backgroundValue: s('surface.background.value'),
      backgroundOverlay: m['surface.background.overlay'] as String?,
      cardFill: s('surface.card.fill'),
      cardBorderColor: s('surface.card.border.color'),
      cardBorderWidth: d('surface.card.border.width'),
      cardBorderStyle: s('surface.card.border.style'),
      cardRadius: i('surface.card.radius'),
      cardBlur: i('surface.card.blur'),
      cardShadow: s('surface.card.shadow'),
      fontFamily: s('typography.fontFamily'),
      typographyScale: s('typography.scale'),
      headingWeight: i('typography.heading.weight'),
      bodyWeight: i('typography.body.weight'),
      letterSpacing: s('typography.letterSpacing'),
      timeDisplayFontFamily: s('typography.timeDisplay.fontFamily'),
      timeDisplayWeight: i('typography.timeDisplay.weight'),
      colorAccent: s('color.accent'),
      colorAccentMuted: s('color.accentMuted'),
      colorTextPrimary: s('color.text.primary'),
      colorTextSecondary: s('color.text.secondary'),
      colorTextTertiary: s('color.text.tertiary'),
      colorDivider: s('color.divider'),
      colorAgentBorder: s('color.agent.border'),
      colorSuccess: s('color.success'),
      colorWarning: s('color.warning'),
      colorAlert: s('color.alert'),
      animationTransition: s('animation.transition'),
      animationSpeed: s('animation.speed'),
      animationCardEntry: s('animation.cardEntry'),
      animationTickerScroll: s('animation.tickerScroll'),
      moodUrgentBorderColor: s('moods.urgent.borderColor'),
      moodUrgentFillColor: s('moods.urgent.fillColor'),
      moodUrgentPulse: b('moods.urgent.pulse'),
      moodUrgentScale: d('moods.urgent.scale'),
      moodUrgentAnimation: s('moods.urgent.animation'),
      moodCelebratoryBorderColor: s('moods.celebratory.borderColor'),
      moodCelebratoryFillColor: s('moods.celebratory.fillColor'),
      moodCelebratoryPulse: b('moods.celebratory.pulse'),
      moodCelebratoryScale: d('moods.celebratory.scale'),
      moodCelebratoryAnimation: s('moods.celebratory.animation'),
      moodSuccessBorderColor: s('moods.success.borderColor'),
      moodSuccessFillColor: s('moods.success.fillColor'),
      moodSuccessPulse: b('moods.success.pulse'),
      moodSuccessScale: d('moods.success.scale'),
      moodSuccessAnimation: s('moods.success.animation'),
      moodMutedBorderColor: s('moods.muted.borderColor'),
      moodMutedFillColor: s('moods.muted.fillColor'),
      moodMutedPulse: b('moods.muted.pulse'),
      moodMutedScale: d('moods.muted.scale'),
      moodMutedAnimation: s('moods.muted.animation'),
      moodMutedOpacity: d('moods.muted.opacity'),
    );
  }

  Map<String, dynamic> toMap() => {
        'surface.background.type': backgroundType,
        'surface.background.value': backgroundValue,
        if (backgroundOverlay != null)
          'surface.background.overlay': backgroundOverlay,
        'surface.card.fill': cardFill,
        'surface.card.border.color': cardBorderColor,
        'surface.card.border.width': cardBorderWidth,
        'surface.card.border.style': cardBorderStyle,
        'surface.card.radius': cardRadius,
        'surface.card.blur': cardBlur,
        'surface.card.shadow': cardShadow,
        'typography.fontFamily': fontFamily,
        'typography.scale': typographyScale,
        'typography.heading.weight': headingWeight,
        'typography.body.weight': bodyWeight,
        'typography.letterSpacing': letterSpacing,
        'typography.timeDisplay.fontFamily': timeDisplayFontFamily,
        'typography.timeDisplay.weight': timeDisplayWeight,
        'color.accent': colorAccent,
        'color.accentMuted': colorAccentMuted,
        'color.text.primary': colorTextPrimary,
        'color.text.secondary': colorTextSecondary,
        'color.text.tertiary': colorTextTertiary,
        'color.divider': colorDivider,
        'color.agent.border': colorAgentBorder,
        'color.success': colorSuccess,
        'color.warning': colorWarning,
        'color.alert': colorAlert,
        'animation.transition': animationTransition,
        'animation.speed': animationSpeed,
        'animation.cardEntry': animationCardEntry,
        'animation.tickerScroll': animationTickerScroll,
        'moods.urgent.borderColor': moodUrgentBorderColor,
        'moods.urgent.fillColor': moodUrgentFillColor,
        'moods.urgent.pulse': moodUrgentPulse,
        'moods.urgent.scale': moodUrgentScale,
        'moods.urgent.animation': moodUrgentAnimation,
        'moods.celebratory.borderColor': moodCelebratoryBorderColor,
        'moods.celebratory.fillColor': moodCelebratoryFillColor,
        'moods.celebratory.pulse': moodCelebratoryPulse,
        'moods.celebratory.scale': moodCelebratoryScale,
        'moods.celebratory.animation': moodCelebratoryAnimation,
        'moods.success.borderColor': moodSuccessBorderColor,
        'moods.success.fillColor': moodSuccessFillColor,
        'moods.success.pulse': moodSuccessPulse,
        'moods.success.scale': moodSuccessScale,
        'moods.success.animation': moodSuccessAnimation,
        'moods.muted.borderColor': moodMutedBorderColor,
        'moods.muted.fillColor': moodMutedFillColor,
        'moods.muted.pulse': moodMutedPulse,
        'moods.muted.scale': moodMutedScale,
        'moods.muted.animation': moodMutedAnimation,
        'moods.muted.opacity': moodMutedOpacity,
      };

  /// Returns a token set whose values match the current hardcoded
  /// [LandfallColors] / [LandfallTypography] constants.
  ///
  /// Used as the fallback when no [LandfallActiveTheme] ancestor is present
  /// in the widget tree, ensuring zero visual change until a theme is applied.
  static LandfallThemeTokens defaults() => LandfallThemeTokens(
        backgroundType: 'solid',
        backgroundValue: '#0D0D0F',
        backgroundOverlay: null,
        cardFill: '#1A1A1F',
        cardBorderColor: '#2C2C35',
        cardBorderWidth: 1.5,
        cardBorderStyle: 'solid',
        cardRadius: 8,
        cardBlur: 0,
        cardShadow: 'none',
        fontFamily: 'Inter',
        typographyScale: 'comfortable',
        headingWeight: 600,
        bodyWeight: 400,
        letterSpacing: 'normal',
        timeDisplayFontFamily: 'System',
        timeDisplayWeight: 200,
        colorAccent: '#4F8EF7',
        colorAccentMuted: 'rgba(79,142,247,0.2)',
        colorTextPrimary: '#F2F2F7',
        colorTextSecondary: '#8E8E9A',
        colorTextTertiary: '#5A5A6A',
        colorDivider: '#2C2C35',
        colorAgentBorder: '#4F8EF7',
        colorSuccess: '#4CAF7D',
        colorWarning: '#FFB347',
        colorAlert: '#FF6B6B',
        animationTransition: 'fade',
        animationSpeed: 'normal',
        animationCardEntry: 'fade',
        animationTickerScroll: 'normal',
        moodUrgentBorderColor: 'rgba(255,59,48,0.8)',
        moodUrgentFillColor: 'rgba(255,59,48,0.1)',
        moodUrgentPulse: true,
        moodUrgentScale: 1.01,
        moodUrgentAnimation: 'pulse',
        moodCelebratoryBorderColor: 'rgba(52,199,89,0.6)',
        moodCelebratoryFillColor: 'rgba(52,199,89,0.08)',
        moodCelebratoryPulse: false,
        moodCelebratoryScale: 1.0,
        moodCelebratoryAnimation: 'glow',
        moodSuccessBorderColor: 'rgba(52,199,89,0.5)',
        moodSuccessFillColor: 'rgba(52,199,89,0.06)',
        moodSuccessPulse: false,
        moodSuccessScale: 1.0,
        moodSuccessAnimation: 'none',
        moodMutedBorderColor: 'rgba(255,255,255,0.1)',
        moodMutedFillColor: 'rgba(255,255,255,0.05)',
        moodMutedPulse: false,
        moodMutedScale: 1.0,
        moodMutedAnimation: 'none',
        moodMutedOpacity: 0.5,
      );

  LandfallThemeTokens copyWith({
    String? backgroundType,
    String? backgroundValue,
    String? backgroundOverlay,
    String? cardFill,
    String? cardBorderColor,
    double? cardBorderWidth,
    String? cardBorderStyle,
    int? cardRadius,
    int? cardBlur,
    String? cardShadow,
    String? fontFamily,
    String? typographyScale,
    int? headingWeight,
    int? bodyWeight,
    String? letterSpacing,
    String? timeDisplayFontFamily,
    int? timeDisplayWeight,
    String? colorAccent,
    String? colorAccentMuted,
    String? colorTextPrimary,
    String? colorTextSecondary,
    String? colorTextTertiary,
    String? colorDivider,
    String? colorAgentBorder,
    String? colorSuccess,
    String? colorWarning,
    String? colorAlert,
    String? animationTransition,
    String? animationSpeed,
    String? animationCardEntry,
    String? animationTickerScroll,
    String? moodUrgentBorderColor,
    String? moodUrgentFillColor,
    bool? moodUrgentPulse,
    double? moodUrgentScale,
    String? moodUrgentAnimation,
    String? moodCelebratoryBorderColor,
    String? moodCelebratoryFillColor,
    bool? moodCelebratoryPulse,
    double? moodCelebratoryScale,
    String? moodCelebratoryAnimation,
    String? moodSuccessBorderColor,
    String? moodSuccessFillColor,
    bool? moodSuccessPulse,
    double? moodSuccessScale,
    String? moodSuccessAnimation,
    String? moodMutedBorderColor,
    String? moodMutedFillColor,
    bool? moodMutedPulse,
    double? moodMutedScale,
    String? moodMutedAnimation,
    double? moodMutedOpacity,
  }) =>
      LandfallThemeTokens(
        backgroundType: backgroundType ?? this.backgroundType,
        backgroundValue: backgroundValue ?? this.backgroundValue,
        backgroundOverlay: backgroundOverlay ?? this.backgroundOverlay,
        cardFill: cardFill ?? this.cardFill,
        cardBorderColor: cardBorderColor ?? this.cardBorderColor,
        cardBorderWidth: cardBorderWidth ?? this.cardBorderWidth,
        cardBorderStyle: cardBorderStyle ?? this.cardBorderStyle,
        cardRadius: cardRadius ?? this.cardRadius,
        cardBlur: cardBlur ?? this.cardBlur,
        cardShadow: cardShadow ?? this.cardShadow,
        fontFamily: fontFamily ?? this.fontFamily,
        typographyScale: typographyScale ?? this.typographyScale,
        headingWeight: headingWeight ?? this.headingWeight,
        bodyWeight: bodyWeight ?? this.bodyWeight,
        letterSpacing: letterSpacing ?? this.letterSpacing,
        timeDisplayFontFamily:
            timeDisplayFontFamily ?? this.timeDisplayFontFamily,
        timeDisplayWeight: timeDisplayWeight ?? this.timeDisplayWeight,
        colorAccent: colorAccent ?? this.colorAccent,
        colorAccentMuted: colorAccentMuted ?? this.colorAccentMuted,
        colorTextPrimary: colorTextPrimary ?? this.colorTextPrimary,
        colorTextSecondary: colorTextSecondary ?? this.colorTextSecondary,
        colorTextTertiary: colorTextTertiary ?? this.colorTextTertiary,
        colorDivider: colorDivider ?? this.colorDivider,
        colorAgentBorder: colorAgentBorder ?? this.colorAgentBorder,
        colorSuccess: colorSuccess ?? this.colorSuccess,
        colorWarning: colorWarning ?? this.colorWarning,
        colorAlert: colorAlert ?? this.colorAlert,
        animationTransition: animationTransition ?? this.animationTransition,
        animationSpeed: animationSpeed ?? this.animationSpeed,
        animationCardEntry: animationCardEntry ?? this.animationCardEntry,
        animationTickerScroll:
            animationTickerScroll ?? this.animationTickerScroll,
        moodUrgentBorderColor:
            moodUrgentBorderColor ?? this.moodUrgentBorderColor,
        moodUrgentFillColor: moodUrgentFillColor ?? this.moodUrgentFillColor,
        moodUrgentPulse: moodUrgentPulse ?? this.moodUrgentPulse,
        moodUrgentScale: moodUrgentScale ?? this.moodUrgentScale,
        moodUrgentAnimation: moodUrgentAnimation ?? this.moodUrgentAnimation,
        moodCelebratoryBorderColor:
            moodCelebratoryBorderColor ?? this.moodCelebratoryBorderColor,
        moodCelebratoryFillColor:
            moodCelebratoryFillColor ?? this.moodCelebratoryFillColor,
        moodCelebratoryPulse: moodCelebratoryPulse ?? this.moodCelebratoryPulse,
        moodCelebratoryScale: moodCelebratoryScale ?? this.moodCelebratoryScale,
        moodCelebratoryAnimation:
            moodCelebratoryAnimation ?? this.moodCelebratoryAnimation,
        moodSuccessBorderColor:
            moodSuccessBorderColor ?? this.moodSuccessBorderColor,
        moodSuccessFillColor: moodSuccessFillColor ?? this.moodSuccessFillColor,
        moodSuccessPulse: moodSuccessPulse ?? this.moodSuccessPulse,
        moodSuccessScale: moodSuccessScale ?? this.moodSuccessScale,
        moodSuccessAnimation: moodSuccessAnimation ?? this.moodSuccessAnimation,
        moodMutedBorderColor: moodMutedBorderColor ?? this.moodMutedBorderColor,
        moodMutedFillColor: moodMutedFillColor ?? this.moodMutedFillColor,
        moodMutedPulse: moodMutedPulse ?? this.moodMutedPulse,
        moodMutedScale: moodMutedScale ?? this.moodMutedScale,
        moodMutedAnimation: moodMutedAnimation ?? this.moodMutedAnimation,
        moodMutedOpacity: moodMutedOpacity ?? this.moodMutedOpacity,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LandfallThemeTokens &&
          backgroundType == other.backgroundType &&
          backgroundValue == other.backgroundValue &&
          colorAccent == other.colorAccent &&
          fontFamily == other.fontFamily;

  @override
  int get hashCode =>
      Object.hash(backgroundType, backgroundValue, colorAccent, fontFamily);
}
