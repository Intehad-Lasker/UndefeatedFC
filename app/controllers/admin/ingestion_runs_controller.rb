module Admin
  # The scraper's run history (written by Python, read here) and a manual
  # ratings refresh, for when ratings need recomputing outside the schedule.
  class IngestionRunsController < BaseController
    def index
      @runs = IngestionRun.recent_first.limit(50)
    end

    def refresh_ratings
      RatingsRefreshJob.perform_later
      redirect_to admin_ingestion_runs_path, notice: "Ratings refresh queued. It takes a few seconds."
    end
  end
end
