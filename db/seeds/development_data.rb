# Invented fighters and fights so the game is playable before the scraper has
# run. Every ufcstats_id starts with "synthetic-", names are made up and do not
# refer to real athletes, and the same seed always produces the same data.
module Seeds
  class DevelopmentData
    PREFIX = "synthetic-".freeze

    FIRST_NAMES = %w[Ace Bruno Cato Dario Emil Felix Gus Hugo Ivo Jax Kai Leon Milo Nico Otto
                     Pavel Quinn Rafe Silas Theo Uri Vito Wade Xavi Yuri Zane].freeze
    WOMEN_FIRST_NAMES = %w[Ada Bea Cleo Dina Eva Faye Gia Hana Iris Juno Kira Lena Mara Nia Ola
                           Pia Rhea Sia Tess Vera].freeze
    LAST_NAMES = %w[Ardent Brakov Castel Dravik Embry Falcone Garrow Halvard Ilkin Jorvik Kestrel
                    Lomax Marrok Nyland Orsini Pellar Quill Rask Sorrel Tavish Ulric Varga Wexley
                    Yarrow Zorin].freeze

    # Ranges for each career stat, from a weak to a strong fighter of that style.
    # Strikes absorbed is listed high-to-low because less is better.
    STYLES = {
      striker: { sig_strikes_landed_per_min: [ 4.0, 7.0 ], sig_strike_accuracy: [ 0.45, 0.58 ],
                 sig_strikes_absorbed_per_min: [ 4.5, 2.5 ], sig_strike_defense: [ 0.55, 0.66 ],
                 takedowns_per_15_min: [ 0.2, 1.2 ], takedown_accuracy: [ 0.20, 0.40 ],
                 takedown_defense: [ 0.60, 0.85 ], submission_attempts_per_15_min: [ 0.0, 0.4 ],
                 finishes: { "ko_tko" => 55, "submission" => 5, "decision" => 40 } },
      wrestler: { sig_strikes_landed_per_min: [ 2.5, 4.0 ], sig_strike_accuracy: [ 0.40, 0.50 ],
                  sig_strikes_absorbed_per_min: [ 3.0, 1.8 ], sig_strike_defense: [ 0.55, 0.65 ],
                  takedowns_per_15_min: [ 3.0, 6.0 ], takedown_accuracy: [ 0.40, 0.55 ],
                  takedown_defense: [ 0.75, 0.92 ], submission_attempts_per_15_min: [ 0.3, 1.0 ],
                  finishes: { "ko_tko" => 20, "submission" => 15, "decision" => 65 } },
      grappler: { sig_strikes_landed_per_min: [ 2.0, 3.5 ], sig_strike_accuracy: [ 0.38, 0.48 ],
                  sig_strikes_absorbed_per_min: [ 3.8, 2.5 ], sig_strike_defense: [ 0.48, 0.58 ],
                  takedowns_per_15_min: [ 1.8, 3.5 ], takedown_accuracy: [ 0.30, 0.45 ],
                  takedown_defense: [ 0.50, 0.70 ], submission_attempts_per_15_min: [ 1.5, 3.0 ],
                  finishes: { "ko_tko" => 10, "submission" => 50, "decision" => 40 } },
      all_rounder: { sig_strikes_landed_per_min: [ 3.5, 5.0 ], sig_strike_accuracy: [ 0.44, 0.52 ],
                     sig_strikes_absorbed_per_min: [ 3.5, 2.5 ], sig_strike_defense: [ 0.56, 0.63 ],
                     takedowns_per_15_min: [ 1.5, 3.0 ], takedown_accuracy: [ 0.35, 0.48 ],
                     takedown_defense: [ 0.65, 0.80 ], submission_attempts_per_15_min: [ 0.5, 1.2 ],
                     finishes: { "ko_tko" => 30, "submission" => 20, "decision" => 50 } }
    }.freeze
    STAT_NAMES = (Fighter::RATE_STATS + Fighter::PERCENT_STATS).freeze

    # Years each division appeared on cards, roughly as in real UFC history.
    DIVISION_YEARS = {
      "Open Weight" => 1994..2000, "Heavyweight" => 1997..2025, "Light Heavyweight" => 1997..2025,
      "Middleweight" => 1997..2025, "Welterweight" => 1998..2025, "Lightweight" => 2001..2025,
      "Featherweight" => 2011..2025, "Bantamweight" => 2011..2025, "Flyweight" => 2012..2025,
      "Women's Bantamweight" => 2013..2025, "Women's Strawweight" => 2014..2025,
      "Women's Flyweight" => 2017..2025, "Women's Featherweight" => 2017..2023
    }.freeze

    Profile = Struct.new(:id, :key, :name, :style, :skill, :debut_year, :retire_year, keyword_init: true)

    def self.seed!(**) = new(**).seed!

    def initialize(rng: Random.new(42), fighters_per_division: 60, years: 1994..2025, bouts_per_event: 6)
      @rng = rng
      @fighters_per_division = fighters_per_division
      @years = years
      @bouts_per_event = bouts_per_event
      @divisions = WeightClass.where(name: active_division_years.keys).index_by(&:name)
    end

    def seed!
      ActiveRecord::Base.transaction do
        profiles = create_fighters
        results = create_events_and_bouts(profiles)
        apply_records(profiles.values.flatten, results)
      end
    end

    private

    attr_reader :rng

    # Each division's years clipped to the requested window; divisions with no
    # overlap are left out entirely.
    def active_division_years
      @active_division_years ||= DIVISION_YEARS.filter_map { |name, span|
        first = [ span.first, @years.first ].max
        last = [ span.last, @years.last ].min
        [ name, first..last ] if first <= last
      }.to_h
    end

    def create_fighters
      rows = []
      profiles = @divisions.to_h do |name, division|
        list = Array.new(@fighters_per_division) do |index|
          profile = build_profile(name, index)
          rows << fighter_row(profile, division)
          profile
        end
        [ name, list ]
      end

      ids = Fighter.insert_all!(rows, returning: %i[id ufcstats_id]).rows.to_h { |id, key| [ key, id ] }
      profiles.values.flatten.each { |profile| profile.id = ids.fetch(profile.key) }
      profiles
    end

    def build_profile(division_name, index)
      span = active_division_years.fetch(division_name)
      debut = rng.rand(span)
      first_names = division_name.start_with?("Women's") ? WOMEN_FIRST_NAMES : FIRST_NAMES
      key = "#{PREFIX}#{division_name.parameterize}-#{index}"
      Profile.new(
        key: key,
        name: "#{first_names.sample(random: rng)} #{LAST_NAMES.sample(random: rng)}",
        style: STYLES.keys.sample(random: rng),
        skill: rng.rand,
        debut_year: debut,
        retire_year: [ debut + rng.rand(3..9), span.last ].min
      )
    end

    def fighter_row(profile, division)
      height = 150 + ((division.limit_lbs || 230) * 0.15).round + rng.rand(-5..5)
      stats = STAT_NAMES.to_h do |stat|
        low, high = STYLES.fetch(profile.style).fetch(stat)
        blend = (profile.skill * 0.7) + (rng.rand * 0.3)
        [ stat, (low + ((high - low) * blend)).round(stat.in?(Fighter::PERCENT_STATS) ? 3 : 2) ]
      end

      {
        ufcstats_id: profile.key,
        name: profile.name,
        height_cm: height,
        reach_cm: height + rng.rand(-3..8),
        stance: weighted_pick({ "Orthodox" => 70, "Southpaw" => 25, "Switch" => 5 }),
        born_on: Date.new(profile.debut_year - rng.rand(22..30), rng.rand(1..12), rng.rand(1..28)),
        **stats
      }
    end

    def create_events_and_bouts(profiles)
      results = Hash.new { |hash, id| hash[id] = Hash.new(0) }

      @years.each do |year|
        1.upto(12) do |month|
          date = Date.new(year, month, rng.rand(1..28))
          event_id = Event.insert!(
            { ufcstats_id: "#{PREFIX}event-#{date.strftime('%Y-%m')}", name: "Synthetic Fight Night #{date.strftime('%b %Y')}",
              held_on: date, location: "Las Vegas, Nevada, USA" }, returning: :id
          ).rows.first.first

          @bouts_per_event.times do |slot|
            create_bout(event_id, date, slot, profiles, results)
          end
        end
      end

      results
    end

    def create_bout(event_id, date, slot, profiles, results)
      division_name, roster = profiles.select { |name, _| active_division_years.fetch(name).cover?(date.year) }
                                      .to_a.sample(random: rng)
      return unless roster

      active = roster.select { |profile| (profile.debut_year..profile.retire_year).cover?(date.year) }
      return if active.size < 2

      red, blue = active.sample(2, random: rng)
      winner, loser = rng.rand < win_chance(red, blue) ? [ red, blue ] : [ blue, red ]
      draw = rng.rand < 0.01
      finish = draw ? "decision" : weighted_pick(STYLES.fetch(winner.style).fetch(:finishes))
      ending_round = finish == "decision" ? 3 : rng.rand(1..3)

      bout_id = Bout.insert!(
        { ufcstats_id: "#{PREFIX}bout-#{event_id}-#{slot}", event_id: event_id,
          weight_class_id: @divisions.fetch(division_name).id, finish: finish,
          finish_detail: { "ko_tko" => "KO/TKO", "submission" => "SUB", "decision" => "U-DEC" }.fetch(finish),
          ending_round: ending_round, ending_time_seconds: finish == "decision" ? 300 : rng.rand(10..299) },
        returning: :id
      ).rows.first.first

      Appearance.insert_all!([
        appearance_row(bout_id, winner, draw ? "draw" : "win", finish),
        appearance_row(bout_id, loser, draw ? "draw" : "loss", finish)
      ])
      results[winner.id][draw ? "draw" : "win"] += 1
      results[loser.id][draw ? "draw" : "loss"] += 1
    end

    def appearance_row(bout_id, profile, outcome, finish)
      won = outcome == "win"
      {
        bout_id: bout_id, fighter_id: profile.id, outcome: outcome,
        knockdowns: won && finish == "ko_tko" ? rng.rand(1..2) : 0,
        submission_attempts: won && finish == "submission" ? rng.rand(1..3) : rng.rand(0..1),
        takedowns_landed: profile.style == :wrestler ? rng.rand(2..7) : rng.rand(0..2),
        sig_strikes_landed: rng.rand(10..90)
      }
    end

    # Professional records include fights before the UFC, so add a few extra wins.
    def apply_records(profiles, results)
      profiles.each do |profile|
        ufc = results[profile.id]
        Fighter.where(id: profile.id).update_all(
          wins: ufc["win"] + rng.rand(3..12), losses: ufc["loss"] + rng.rand(0..3), draws: ufc["draw"]
        )
      end
    end

    def win_chance(red, blue)
      1.0 / (1 + Math.exp(-(red.skill - blue.skill) * 6))
    end

    def weighted_pick(weights)
      roll = rng.rand(weights.values.sum)
      weights.each do |value, weight|
        return value if roll < weight

        roll -= weight
      end
    end
  end
end
