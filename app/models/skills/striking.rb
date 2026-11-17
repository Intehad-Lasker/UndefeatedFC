module Skills
  # Significant strikes landed per minute, with a bonus for accuracy, so an
  # efficient striker beats one who lands the same amount by throwing more.
  class Striking < Base
    def description = "Significant strikes landed per minute, rewarded for accuracy"

    def raw_score(fighter)
      fighter.sig_strikes_landed_per_min.to_f * (0.5 + fighter.sig_strike_accuracy.to_f)
    end
  end
end
