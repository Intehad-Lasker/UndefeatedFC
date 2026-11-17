# Runs nightly (config/recurring.yml) so the next day's challenge exists before
# anyone asks for it. Creating today's as well makes a missed run harmless, and
# DailyChallenge.for_day still creates a challenge on first use as a fallback.
class CreateDailyChallengeJob < ApplicationJob
  queue_as :default

  def perform(today = Time.now.utc.to_date)
    [ today, today + 1 ].map { |day| DailyChallenge.for_day(day) }
  end
end
