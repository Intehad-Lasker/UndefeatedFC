module Skills
  # How often a fighter ends fights on the feet: the share of wins by KO/TKO,
  # plus knockdowns per fight so heavy hitters who go the distance still count.
  class Power < Base
    def description = "Share of wins by knockout, plus knockdowns per fight"

    def raw_score(fighter)
      record = fighter.ufc_record
      record.ko_win_rate + (0.5 * record.knockdowns_per_fight)
    end
  end
end
