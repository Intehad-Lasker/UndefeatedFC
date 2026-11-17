# Builds drafts with picked rounds directly, for tests that need a full or
# nearly full draft without spinning through the services.
module DraftBuilder
  def build_draft(ratings:, seed: 42, open_round: false)
    draft = Draft.create!(seed: seed)
    ratings.each_with_index do |rating, index|
      fighter = Fighter.create!(ufcstats_id: "synthetic-built-#{SecureRandom.hex(4)}", name: "Built #{index}")
      DraftRound.create!(
        draft: draft, number: index + 1, weight_class: weight_classes(:lightweight), era: eras(:modern),
        fighter: fighter, slot: Skills.keys.fetch(index), rating: rating, picked_at: Time.current
      )
    end
    if open_round
      DraftRound.create!(draft: draft, number: ratings.size + 1, weight_class: weight_classes(:lightweight), era: eras(:modern))
    end
    Draft.with_rounds.find(draft.id)
  end
end
