# Like drafts: the seed is never sent, and pool fighters carry no ratings.
json.call(@match, :id, :status, :current_seat)
json.your_seat @you&.seat
json.round(@match.drafting? ? @match.current_round : nil)
json.players @match.players, :seat, :display_name

if @pool
  json.pool do
    json.weight_class { json.call(@weight_class, :id, :name) }
    json.era { json.call(@era, :id, :name, :label) }
    json.fighters @fighters, partial: "api/v1/fighters/fighter", as: :fighter
  end
else
  json.pool nil
end

json.boards Match::SEATS do |seat|
  picks = @match.picks_for(seat).index_by(&:slot)
  json.seat seat
  json.slots Skills.all do |skill|
    pick = picks[skill.key]
    json.call(skill, :key, :label)
    json.rating pick&.rating
    if pick
      json.fighter { json.partial! "api/v1/fighters/fighter", fighter: pick.fighter }
    else
      json.fighter nil
    end
  end
end

if @match.completed?
  json.result do
    json.winner_seat @match.winner_seat
    json.merge! @match.result
  end
else
  json.result nil
end
