class Fighter < ApplicationRecord
  has_many :appearances, dependent: :destroy
  has_many :bouts, through: :appearances
  has_many :ratings, class_name: "FighterRating", dependent: :delete_all

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

  UFC_RECORD_COLUMNS = {
    ufc_fights: "COUNT(appearances.id)",
    ufc_wins: "COUNT(*) FILTER (WHERE appearances.outcome = 'win')",
    ufc_losses: "COUNT(*) FILTER (WHERE appearances.outcome = 'loss')",
    ko_wins: "COUNT(*) FILTER (WHERE appearances.outcome = 'win' AND bouts.finish = 'ko_tko')",
    submission_wins: "COUNT(*) FILTER (WHERE appearances.outcome = 'win' AND bouts.finish = 'submission')",
    ko_losses: "COUNT(*) FILTER (WHERE appearances.outcome = 'loss' AND bouts.finish = 'ko_tko')",
    total_knockdowns: "COALESCE(SUM(appearances.knockdowns), 0)"
  }.freeze

  # Adds UFC fight and finish counts to each fighter in one grouped query, so a
  # whole roster can be rated without a query per fighter.
  scope :with_ufc_record, -> {
    left_joins(appearances: :bout)
      .select("fighters.*", *UFC_RECORD_COLUMNS.map { |name, sql| "#{sql} AS #{name}" })
      .group(:id)
  }

  def ufc_record
    unless has_attribute?(:ufc_fights)
      raise ArgumentError, "load the fighter through Fighter.with_ufc_record to read its UFC record"
    end

    UfcRecord.new(
      fights: self[:ufc_fights], wins: self[:ufc_wins], losses: self[:ufc_losses],
      ko_wins: self[:ko_wins], submission_wins: self[:submission_wins],
      ko_losses: self[:ko_losses], knockdowns: self[:total_knockdowns]
    )
  end

  # {"striking" => 87, "power" => 64, ...}; call on fighters loaded with includes(:ratings).
  def rating_by_skill
    ratings.to_h { |rating| [ rating.skill, rating.value ] }
  end

  # Professional record, e.g. "26-1-0" or "26-1-0 (1 NC)".
  def record
    base = [ wins, losses, draws ].join("-")
    no_contests.positive? ? "#{base} (#{no_contests} NC)" : base
  end
end
