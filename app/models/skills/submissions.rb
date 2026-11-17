module Skills
  # Threat on the mat: submission attempts per 15 minutes plus the share of wins
  # that came by submission, so finishing ability counts, not just attempts.
  class Submissions < Base
    FINISH_WEIGHT = 3

    def description = "Submission attempts per 15 minutes, plus share of wins by submission"

    def raw_score(fighter)
      fighter.submission_attempts_per_15_min.to_f + (FINISH_WEIGHT * fighter.ufc_record.submission_win_rate)
    end
  end
end
