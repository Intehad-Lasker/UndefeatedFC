json.day @day
json.entries @entries do |entry|
  json.call(entry, :rank, :draft_id, :display_name, :wins, :losses, :overall, :completed_at)
  json.record "#{entry[:wins]}-#{entry[:losses]}"
  json.undefeated entry[:losses].zero?
end
