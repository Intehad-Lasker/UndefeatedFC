module Skills
  # Avoiding damage: the share of opponents' strikes avoided, minus strikes
  # absorbed per minute. Defense percentage is scaled by 10 so both parts sit on
  # a similar range (roughly 4-7 against 1-6).
  class Defense < Base
    AVOIDANCE_WEIGHT = 10

    def description = "Share of strikes avoided, minus strikes absorbed per minute"

    def raw_score(fighter)
      (AVOIDANCE_WEIGHT * fighter.sig_strike_defense.to_f) - fighter.sig_strikes_absorbed_per_min.to_f
    end
  end
end
