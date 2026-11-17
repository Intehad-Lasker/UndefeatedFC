module Ratings
  # Recomputes every fighter's rating in every skill and writes them in bulk.
  #
  # Fighters and their UFC records come from one grouped query, each skill
  # scores them in Ruby, and the results are upserted in batches, so the whole
  # roster is rated in a handful of queries however many fighters there are.
  class Refresher
    BATCH_SIZE = 5_000

    def initialize(skills: Skills.all, normalizer: Normalizer.new)
      @skills = skills
      @normalizer = normalizer
    end

    # Returns the number of ratings written.
    def call
      fighters = Fighter.with_ufc_record.to_a
      rows = @skills.flat_map { |skill| rows_for(skill, fighters) }

      FighterRating.transaction do
        FighterRating.where.not(skill: @skills.map(&:key)).delete_all
        rows.each_slice(BATCH_SIZE) do |batch|
          FighterRating.upsert_all(batch, unique_by: %i[fighter_id skill], update_only: %i[value])
        end
      end

      rows.size
    end

    private

    def rows_for(skill, fighters)
      entries = fighters.map do |fighter|
        Normalizer::Entry.new(id: fighter.id, raw: skill.raw_score(fighter), fights: fighter.ufc_record.fights)
      end

      @normalizer.call(entries).map do |fighter_id, value|
        { fighter_id: fighter_id, skill: skill.key, value: value }
      end
    end
  end
end
