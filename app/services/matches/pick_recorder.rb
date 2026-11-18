module Matches
  # Records one pick in a match. Under the match's row lock it checks that it
  # is this player's turn, the slot is theirs to fill, and the fighter is in
  # this round's pool and not already taken by either player.
  class PickRecorder
    def initialize(match, player_id:, fighter_id:, slot:, user: nil)
      @match = match
      @player_id = player_id
      @user = user
      @fighter_id = fighter_id
      @slot = slot
    end

    # Returns the new MatchPick.
    def call
      @match.transaction do
        @match.lock_with_everything!
        seat = turn_seat!
        skill = skill!(seat)
        fighter = fighter_in_pool!

        pick = @match.picks.create!(number: @match.next_pick_number, seat: seat, fighter: fighter, slot: skill.key,
                                    rating: FighterRating.where(fighter: fighter, skill: skill.key).pick(:value) || 0)
        Finisher.new(@match).call if @match.picks.size == Match::PICKS
        @match.announce_change
        pick
      end
    rescue ActiveRecord::RecordNotUnique
      raise RuleViolation, "That pick clashes with another one. Refresh and try again."
    end

    private

    def turn_seat!
      raise RuleViolation, "Waiting for an opponent to join." if @match.waiting?
      raise RuleViolation, "This match is already finished." if @match.completed?

      player = @match.player_for(player_id: @player_id, user: @user)
      raise RuleViolation, "You're not playing in this match." unless player
      raise RuleViolation, "It's your opponent's turn." unless player.seat == @match.current_seat

      player.seat
    end

    def skill!(seat)
      skill = Skills.find(@slot)
      raise RuleViolation, "Your #{skill.label} slot is already filled." unless @match.open_slots_for(seat).include?(skill.key)

      skill
    rescue Skills::UnknownSkill
      raise RuleViolation, "#{@slot.to_s.inspect} is not a slot."
    end

    def fighter_in_pool!
      raise RuleViolation, "That fighter has already been drafted." if @match.drafted_fighter_ids.include?(@fighter_id.to_i)

      pool = @match.current_pool
      Fighter.in_pool(weight_class: pool[:weight_class_id], era: pool[:era_id]).find_by(id: @fighter_id) or
        raise RuleViolation, "That fighter isn't in this round's pool."
    end
  end
end
