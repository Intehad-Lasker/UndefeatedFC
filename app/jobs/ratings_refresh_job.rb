# Recomputes all fighter ratings in the background. Solid Queue's concurrency
# limit makes sure two refreshes never run at the same time.
class RatingsRefreshJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "ratings_refresh"

  def perform
    Ratings::Refresher.new.call
  end
end
