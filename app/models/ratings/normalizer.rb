module Ratings
  # Turns raw skill scores into 0-99 ratings relative to every other fighter.
  #
  # 1. Shrinkage. Each raw score is pulled toward the average, more strongly the
  #    fewer UFC fights it rests on:
  #      adjusted = (fights * raw + PRIOR_FIGHTS * mean) / (fights + PRIOR_FIGHTS)
  #    One knockout in one fight is not yet proof of elite power; after twenty
  #    fights the fighter's own numbers dominate.
  # 2. Percentile. Adjusted scores are ranked against each other and scaled to
  #    0..99. The lowest gets 0, the highest 99, and ties share the same rating.
  #
  # Ranking (rather than min-max scaling) means one outlier cannot squash
  # everyone else into a narrow band, and skills on very different scales all
  # come out comparable.
  class Normalizer
    Entry = Data.define(:id, :raw, :fights)

    PRIOR_FIGHTS = 5
    TOP = FighterRating::RANGE.max

    def initialize(prior_fights: PRIOR_FIGHTS)
      @prior_fights = prior_fights
    end

    # entries: Array of Entry. Returns { id => rating }.
    def call(entries)
      return {} if entries.empty?

      mean = population_mean(entries)
      adjusted = entries.to_h { |entry| [ entry.id, shrink(entry, mean) ] }
      percentiles(adjusted)
    end

    private

    def population_mean(entries)
      experienced = entries.select { |entry| entry.fights.positive? }
      pool = experienced.presence || entries
      pool.sum(&:raw).fdiv(pool.size)
    end

    def shrink(entry, mean)
      ((entry.fights * entry.raw) + (@prior_fights * mean)).fdiv(entry.fights + @prior_fights)
    end

    def percentiles(scores)
      sorted = scores.values.sort
      last_index = sorted.size - 1

      scores.transform_values do |score|
        next (TOP / 2.0).round if last_index.zero?

        below = sorted.bsearch_index { |value| value >= score }
        through = sorted.bsearch_index { |value| value > score } || sorted.size
        midpoint_rank = (below + through - 1) / 2.0
        (midpoint_rank / last_index * TOP).round
      end
    end
  end
end
