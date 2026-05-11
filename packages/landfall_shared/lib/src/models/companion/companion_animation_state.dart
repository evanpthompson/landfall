enum CompanionAnimationState {
  // Core idle states
  idle,
  idleCalm,

  // Event reactions
  reactUrgent,
  reactCelebratory,
  reactWeatherRain,
  reactWeatherSun,
  reactNight,

  // Lifecycle
  evolve,

  // QR interactions
  pet,
  play,
  playLeft,
  playSprint,
  feed,

  // Ambient
  lookAtViewer,
}
