# A fighter as players see them while drafting: identity and career stats.
# Ratings are deliberately absent; they are revealed only once a fighter is picked.
json.call(fighter, :id, :name, :nickname, :record, :height_cm, :reach_cm, :stance)
json.stats do
  (Fighter::RATE_STATS + Fighter::PERCENT_STATS).each { |stat| json.set! stat, fighter.public_send(stat).to_f }
end
if fighter.has_attribute?(:ufc_fights)
  json.ufc_record do
    record = fighter.ufc_record
    json.call(record, :fights, :wins, :losses, :ko_wins, :submission_wins)
  end
end
