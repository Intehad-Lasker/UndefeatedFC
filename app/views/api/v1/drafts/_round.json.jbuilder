json.number round.number
json.weight_class { json.call(round.weight_class, :id, :name) }
json.era { json.call(round.era, :id, :name, :label) }
json.picked round.picked?
json.slot round.slot
json.rating round.rating
if round.picked?
  json.fighter { json.partial! "api/v1/fighters/fighter", fighter: round.fighter }
else
  json.fighter nil
end
