# Weight classes and eras every environment needs. Running it again updates rows
# in place instead of duplicating them.
module Seeds
  module ReferenceData
    WEIGHT_CLASSES = [
      { name: "Flyweight", limit_lbs: 125 },
      { name: "Bantamweight", limit_lbs: 135 },
      { name: "Featherweight", limit_lbs: 145 },
      { name: "Lightweight", limit_lbs: 155 },
      { name: "Welterweight", limit_lbs: 170 },
      { name: "Middleweight", limit_lbs: 185 },
      { name: "Light Heavyweight", limit_lbs: 205 },
      { name: "Heavyweight", limit_lbs: 265 },
      { name: "Women's Strawweight", limit_lbs: 115 },
      { name: "Women's Flyweight", limit_lbs: 125 },
      { name: "Women's Bantamweight", limit_lbs: 135 },
      { name: "Women's Featherweight", limit_lbs: 145 },
      { name: "Open Weight", limit_lbs: nil },
      { name: "Catch Weight", limit_lbs: nil, spinnable: false }
    ].freeze

    ERAS = [
      { name: "Pioneer", starts_on: "1993-11-12", ends_on: "2000-12-31" },
      { name: "Early Zuffa", starts_on: "2001-01-01", ends_on: "2005-12-31" },
      { name: "Expansion", starts_on: "2006-01-01", ends_on: "2010-12-31" },
      { name: "Mainstream", starts_on: "2011-01-01", ends_on: "2015-12-31" },
      { name: "Modern", starts_on: "2016-01-01", ends_on: "2020-12-31" },
      { name: "Current", starts_on: "2021-01-01", ends_on: nil }
    ].freeze

    def self.seed!
      WEIGHT_CLASSES.each.with_index(1) do |attributes, position|
        WeightClass.find_or_initialize_by(name: attributes[:name])
          .update!(spinnable: true, **attributes, position: position)
      end

      ERAS.each do |attributes|
        Era.find_or_initialize_by(name: attributes[:name]).update!(attributes)
      end
    end
  end
end
