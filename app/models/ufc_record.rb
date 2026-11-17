# A fighter's results inside the UFC, built from appearances. Rates return 0.0
# when there is nothing to divide by, so callers never have to guard for it.
UfcRecord = Data.define(:fights, :wins, :losses, :ko_wins, :submission_wins, :ko_losses, :knockdowns) do
  def ko_win_rate = ratio(ko_wins, wins)
  def submission_win_rate = ratio(submission_wins, wins)
  def ko_loss_rate = ratio(ko_losses, fights)
  def knockdowns_per_fight = ratio(knockdowns, fights)

  private

  def ratio(part, whole) = whole.zero? ? 0.0 : part.fdiv(whole)
end
