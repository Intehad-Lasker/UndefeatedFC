require "test_helper"
require "rake"

class AdminRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |task| task.name == "admin:grant" }
    Rake::Task["admin:grant"].reenable
  end

  test "admin:grant promotes an account" do
    assert_output(/FirstPlayer is now an admin/) { Rake::Task["admin:grant"].invoke(" ONE@example.com ") }

    assert users(:one).reload.admin?
  end
end
