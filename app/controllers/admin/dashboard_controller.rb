module Admin
  class DashboardController < BaseController
    def show
      @counts = { fighters: Fighter.count, bouts: Bout.count, drafts: Draft.count, players: User.count }
      @latest_run = IngestionRun.recent_first.first
      @today = DailyChallenge.today
      @today_attempts = @today.drafts.count
      @today_finished = @today.drafts.completed.count
    end
  end
end
