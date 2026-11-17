json.drafts @drafts do |draft|
  json.call(draft, :id, :status, :overall, :wins, :losses, :record, :created_at, :completed_at)
  json.undefeated draft.undefeated?
  json.picks_made draft[:picks_made]
end
