json.partial! "api/v1/fighters/fighter", fighter: @fighter
json.born_on @fighter.born_on

json.pools @pools do |weight_class, era|
  json.weight_class weight_class
  json.era era
end

json.recent_bouts @appearances do |appearance|
  bout = appearance.bout
  opponent = bout.appearances.find { |other| other.fighter_id != @fighter.id }&.fighter
  json.event bout.event.name
  json.held_on bout.event.held_on
  json.weight_class bout.weight_class.name
  json.outcome appearance.outcome
  json.finish bout.finish
  json.finish_detail bout.finish_detail
  json.ending_round bout.ending_round
  json.opponent opponent && { id: opponent.id, name: opponent.name }
end
