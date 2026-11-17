# The seed is never sent: it would let a player predict the next spins.
json.call(@draft, :id, :status, :created_at, :completed_at)
json.owned @owned

json.slots Skills.all do |skill|
  round = @draft.picked_rounds.find { |picked| picked.slot == skill.key }
  json.call(skill, :key, :label)
  json.round_number round&.number
  json.rating round&.rating
  if round
    json.fighter { json.partial! "api/v1/fighters/fighter", fighter: round.fighter }
  else
    json.fighter nil
  end
end

json.rounds @draft.rounds, partial: "api/v1/drafts/round", as: :round

if (open_round = @draft.open_round)
  json.open_round do
    json.partial! "api/v1/drafts/round", round: open_round
    json.pool @pool, partial: "api/v1/fighters/fighter", as: :fighter
  end
else
  json.open_round nil
end

if @draft.completed?
  json.result do
    json.call(@draft, :overall, :wins, :losses, :record)
    json.undefeated @draft.undefeated?
    json.fights @draft.fight_log
  end
else
  json.result nil
end
