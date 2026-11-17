require "test_helper"

class RatingsRefreshJobTest < ActiveJob::TestCase
  test "recomputes ratings" do
    FighterRating.delete_all

    RatingsRefreshJob.perform_now

    assert_equal Fighter.count * Skills.all.size, FighterRating.count
  end

  test "is enqueued on the default queue" do
    assert_enqueued_with(job: RatingsRefreshJob, queue: "default") { RatingsRefreshJob.perform_later }
  end
end
