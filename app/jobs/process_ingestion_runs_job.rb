# Runs every few minutes (config/recurring.yml). When the scraper has finished a
# successful load since the last check, recompute ratings and mark those runs
# done. Runs that succeed while this is working stay pending for the next tick.
class ProcessIngestionRunsJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "ratings_refresh"

  def perform
    pending_ids = IngestionRun.awaiting_ratings.ids
    return if pending_ids.empty?

    Ratings::Refresher.new.call
    IngestionRun.where(id: pending_ids).update_all(ratings_refreshed_at: Time.current, updated_at: Time.current)
  end
end
