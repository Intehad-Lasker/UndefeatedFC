require_relative "pool_builder"

# Builds a two-player match whose every round uses a pool filled with enough
# fighters, so pick tests run against real pool queries.
module MatchBuilder
  include PoolBuilder

  HOST = "33333333-0000-4000-8000-000000000001".freeze
  GUEST = "33333333-0000-4000-8000-000000000002".freeze

  def build_match
    roster = fill_pool(weight_class: weight_classes(:welterweight), era: eras(:modern), fighters: 20)
    pool = [ weight_classes(:welterweight).id, eras(:modern).id ]
    match = Match.create!(status: :drafting, pools: Array.new(Match::ROUNDS) { pool })
    match.players.create!(seat: 1, player_id: HOST, display_name: "Host")
    match.players.create!(seat: 2, player_id: GUEST, display_name: "Guest")
    [ match, roster ]
  end

  def pick(match, player_id, fighter, slot)
    Matches::PickRecorder.new(Match.find(match.id), player_id: player_id, fighter_id: fighter.id, slot: slot).call
  end
end
