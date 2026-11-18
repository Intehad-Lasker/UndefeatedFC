# A head-to-head draft between two players. They share six rounds (one pool
# each, chosen at creation) and alternate picks in snake order, so neither
# player always gets first choice: 1, 2, 2, 1, 1, 2, 2, 1, 1, 2, 2, 1.
class Match < ApplicationRecord
  ROUNDS = Skills.all.size
  PICKS = ROUNDS * 2
  SEATS = [ 1, 2 ].freeze

  has_many :players, -> { order(:seat) }, class_name: "MatchPlayer", inverse_of: :match, dependent: :delete_all
  has_many :picks, -> { order(:number) }, class_name: "MatchPick", inverse_of: :match, dependent: :delete_all

  enum :status, { waiting: "waiting", drafting: "drafting", completed: "completed" }, validate: true

  attribute :seed, default: -> { SecureRandom.random_number(Draft::SEED_RANGE) }

  validates :seed, numericality: { only_integer: true, in: Draft::SEED_RANGE }
  validates :winner_seat, inclusion: { in: SEATS }, allow_nil: true

  scope :with_everything, -> { includes(:players, picks: :fighter) }

  # Which seat picks on a given turn (1-based).
  def self.seat_for_pick(number)
    round = (number + 1) / 2
    first_of_round = number.odd?
    first_seat = round.odd? ? 1 : 2
    first_of_round ? first_seat : (SEATS - [ first_seat ]).first
  end

  def self.round_for_pick(number) = (number + 1) / 2

  # Queues a live update once the current transaction commits, so a rolled-back
  # join or pick is never announced.
  def announce_change
    match_id = id
    ActiveRecord.after_all_transactions_commit { MatchBroadcastJob.perform_later(match_id) }
  end

  # Locks the match row (SELECT ... FOR UPDATE) and reloads players and picks,
  # so two players' simultaneous requests are handled one after the other.
  def lock_with_everything!
    lock!
    ActiveRecord::Associations::Preloader.new(records: [ self ], associations: [ :players, { picks: :fighter } ]).call
    self
  end

  # The helpers below read loaded players and picks (use .with_everything).

  def next_pick_number = picks.size + 1
  def current_seat = (drafting? ? self.class.seat_for_pick(next_pick_number) : nil)
  def current_round = self.class.round_for_pick(next_pick_number)

  def current_pool
    return nil unless drafting?

    weight_class_id, era_id = pools.fetch(current_round - 1)
    { weight_class_id: weight_class_id, era_id: era_id }
  end

  def player_for(player_id: nil, user: nil)
    players.find { |player| (user && player.user_id == user.id) || (player_id.present? && player.player_id == player_id) }
  end

  def picks_for(seat) = picks.select { |pick| pick.seat == seat }
  def open_slots_for(seat) = Skills.keys - picks_for(seat).map(&:slot)
  def drafted_fighter_ids = picks.map(&:fighter_id)
end
