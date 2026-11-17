class Fighter < ApplicationRecord
  RECORD_STATS = %i[wins losses draws no_contests].freeze
  RATE_STATS = %i[sig_strikes_landed_per_min sig_strikes_absorbed_per_min
                  takedowns_per_15_min submission_attempts_per_15_min].freeze
  PERCENT_STATS = %i[sig_strike_accuracy sig_strike_defense takedown_accuracy takedown_defense].freeze

  validates :ufcstats_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates(*RECORD_STATS, numericality: { only_integer: true, greater_than_or_equal_to: 0 })
  validates(*RATE_STATS, numericality: { greater_than_or_equal_to: 0 })
  validates(*PERCENT_STATS, numericality: { in: 0..1 })
  validates :height_cm, :reach_cm, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  # Professional record, e.g. "26-1-0" or "26-1-0 (1 NC)".
  def record
    base = [ wins, losses, draws ].join("-")
    no_contests.positive? ? "#{base} (#{no_contests} NC)" : base
  end
end
