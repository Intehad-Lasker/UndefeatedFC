class AddDailyChallengeToDrafts < ActiveRecord::Migration[8.1]
  def change
    # NULL for ordinary drafts; set for a player's attempt at a daily challenge.
    add_reference :drafts, :daily_challenge, foreign_key: true, index: false
  end
end
