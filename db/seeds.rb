# Loaded by bin/rails db:seed and db:setup. Safe to run more than once.
require_relative "seeds/reference_data"
require_relative "seeds/development_data"

Seeds::ReferenceData.seed!

# Invented fighters so the game works locally before the scraper has run.
# Skipped once any fighters exist, so real data is never mixed with it.
if Rails.env.development? && Fighter.none?
  Seeds::DevelopmentData.seed!
  puts "Seeded #{Fighter.count} synthetic fighters across #{Bout.count} bouts."
end
