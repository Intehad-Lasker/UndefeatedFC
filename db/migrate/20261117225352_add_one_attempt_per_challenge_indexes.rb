class AddOneAttemptPerChallengeIndexes < ActiveRecord::Migration[8.1]
  def change
    # One attempt per browser and one per account for each daily challenge.
    # Partial indexes, so ordinary drafts (no challenge) are unaffected.
    add_index :drafts, %i[daily_challenge_id player_id], unique: true,
      where: "daily_challenge_id IS NOT NULL", name: "index_drafts_one_challenge_attempt_per_browser"
    add_index :drafts, %i[daily_challenge_id user_id], unique: true,
      where: "daily_challenge_id IS NOT NULL AND user_id IS NOT NULL", name: "index_drafts_one_challenge_attempt_per_account"
  end
end
