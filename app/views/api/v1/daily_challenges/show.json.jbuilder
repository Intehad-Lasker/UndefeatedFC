json.day @challenge.day
if @attempt
  json.attempt do
    json.call(@attempt, :id, :status, :overall, :record)
    json.undefeated @attempt.undefeated?
  end
else
  json.attempt nil
end
