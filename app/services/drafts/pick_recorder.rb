module Drafts
  # Records a pick: the chosen fighter fills one empty slot from the open round.
  # The pick that fills the last slot also scores the draft, in the same
  # transaction, so a draft is never full but unscored.
  #
  # Every rule is checked under the draft's row lock, and the unique indexes on
  # draft_rounds back them up, so a double-click or two tabs cannot draft the
  # same fighter twice or fill a slot twice.
  class PickRecorder
    def initialize(draft, fighter_id:, slot:)
      @draft = draft
      @fighter_id = fighter_id
      @slot = slot
    end

    # Returns the completed DraftRound.
    def call
      @draft.transaction do
        @draft.lock_with_rounds!
        round = open_round!
        skill = skill!
        fighter = fighter_in_pool!(round)

        round.update!(fighter: fighter, slot: skill.key, rating: rating(fighter, skill), picked_at: Time.current)
        Scorer.new(@draft).call if @draft.all_slots_filled?
        round
      end
    rescue ActiveRecord::RecordNotUnique
      raise RuleViolation, "That pick clashes with another one. Refresh and try again."
    end

    private

    def open_round!
      raise RuleViolation, "This draft is already finished." if @draft.completed?

      @draft.open_round or raise RuleViolation, "Spin before picking a fighter."
    end

    def skill!
      skill = Skills.find(@slot)
      raise RuleViolation, "Your #{skill.label} slot is already filled." if @draft.filled_slots.include?(skill.key)

      skill
    rescue Skills::UnknownSkill
      raise RuleViolation, "#{@slot.to_s.inspect} is not a slot."
    end

    def fighter_in_pool!(round)
      if @draft.drafted_fighter_ids.include?(@fighter_id.to_i)
        raise RuleViolation, "You already drafted that fighter."
      end

      Fighter.in_pool(weight_class: round.weight_class, era: round.era).find_by(id: @fighter_id) or
        raise RuleViolation, "That fighter did not fight at #{round.weight_class.name} in the #{round.era.label} era."
    end

    # Snapshot of the current rating. A fighter not rated yet counts as 0.
    def rating(fighter, skill)
      FighterRating.where(fighter: fighter, skill: skill.key).pick(:value) || 0
    end
  end
end
