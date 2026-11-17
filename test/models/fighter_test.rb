require "test_helper"

class FighterTest < ActiveSupport::TestCase
  test "fixtures are valid" do
    assert fighters(:striker).valid?
    assert fighters(:wrestler).valid?
  end

  test "requires a unique UFCStats id" do
    fighter = Fighter.new(ufcstats_id: fighters(:striker).ufcstats_id, name: "Copy")

    assert_not fighter.valid?
    assert_includes fighter.errors[:ufcstats_id], "has already been taken"
  end

  test "requires a name" do
    assert_not Fighter.new(ufcstats_id: "new").valid?
  end

  test "rejects percentages outside 0 to 1" do
    fighter = fighters(:striker)
    fighter.sig_strike_accuracy = 1.2

    assert_not fighter.valid?
  end

  test "rejects negative rates and record counts" do
    fighter = fighters(:striker)
    fighter.takedowns_per_15_min = -1
    fighter.losses = -1

    assert_not fighter.valid?
    assert fighter.errors.key?(:takedowns_per_15_min)
    assert fighter.errors.key?(:losses)
  end

  test "database rejects out-of-range percentages even when validations are skipped" do
    assert_raises(ActiveRecord::StatementInvalid) do
      fighters(:striker).update_column(:takedown_defense, 1.5)
    end
  end

  test "record formats wins, losses and draws" do
    assert_equal "20-3-0", fighters(:striker).record
  end

  test "record mentions no contests when there are any" do
    assert_equal "25-1-0 (1 NC)", fighters(:wrestler).record
  end
end

class FighterUfcRecordTest < ActiveSupport::TestCase
  def record_for(fixture)
    Fighter.with_ufc_record.find(fighters(fixture).id).ufc_record
  end

  test "counts UFC fights, wins and losses from appearances" do
    record = record_for(:striker)

    assert_equal 3, record.fights
    assert_equal 1, record.wins
    assert_equal 2, record.losses
  end

  test "splits wins and losses by finish" do
    striker = record_for(:striker)
    grappler = record_for(:grappler)

    assert_equal 1, striker.ko_wins
    assert_equal 2, striker.knockdowns
    assert_equal 1, grappler.submission_wins
    assert_equal 1, grappler.ko_losses
  end

  test "derives rates" do
    grappler = record_for(:grappler)

    assert_in_delta 1.0, grappler.submission_win_rate
    assert_in_delta 0.5, grappler.ko_loss_rate
    assert_in_delta 2.0 / 3, record_for(:striker).knockdowns_per_fight
  end

  test "a fighter with no UFC bouts has an empty record and zero rates" do
    newcomer = Fighter.create!(ufcstats_id: "synthetic-newcomer", name: "New Comer")
    record = Fighter.with_ufc_record.find(newcomer.id).ufc_record

    assert_equal 0, record.fights
    assert_in_delta 0.0, record.ko_win_rate
  end

  test "loads every fighter's record in a single query" do
    queries = []
    callback = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      Fighter.with_ufc_record.each(&:ufc_record)
    end

    assert_equal 1, queries.size
  end

  test "explains how to load the record when it was not selected" do
    error = assert_raises(ArgumentError) { fighters(:striker).ufc_record }

    assert_match "with_ufc_record", error.message
  end
end
