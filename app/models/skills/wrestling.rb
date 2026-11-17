module Skills
  # Takedown offense and defense together. Offense is takedowns landed per 15
  # minutes with an accuracy bonus; defense (a 0..1 rate) is scaled by 3 so a
  # strong defensive wrestler competes with a strong offensive one.
  class Wrestling < Base
    DEFENSE_WEIGHT = 3

    def description = "Takedowns landed per 15 minutes, rewarded for accuracy, plus takedown defense"

    def raw_score(fighter)
      offense = fighter.takedowns_per_15_min.to_f * (0.5 + fighter.takedown_accuracy.to_f)
      offense + (DEFENSE_WEIGHT * fighter.takedown_defense.to_f)
    end
  end
end
