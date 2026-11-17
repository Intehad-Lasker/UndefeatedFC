# Creates enough fighters and bouts in one weight class and era for the
# Spinner to consider the pool eligible.
module PoolBuilder
  def fill_pool(weight_class:, era:, fighters: Drafts::Spinner::MIN_POOL_SIZE, on: era.starts_on + 30)
    event = Event.create!(ufcstats_id: "synthetic-pool-#{SecureRandom.hex(4)}", name: "Pool Night", held_on: on)
    roster = Array.new(fighters) do |index|
      Fighter.create!(ufcstats_id: "synthetic-pool-#{SecureRandom.hex(4)}", name: "Pool Fighter #{index}")
    end
    roster.each_slice(2) do |red, blue|
      bout = Bout.create!(ufcstats_id: "synthetic-pool-#{SecureRandom.hex(4)}", event: event, weight_class: weight_class, finish: "decision")
      bout.appearances.create!(fighter: red, outcome: "win")
      bout.appearances.create!(fighter: blue, outcome: "loss") if blue
    end
    roster
  end
end
