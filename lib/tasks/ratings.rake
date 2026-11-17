namespace :ratings do
  desc "Recompute every fighter's skill ratings"
  task refresh: :environment do
    count = Ratings::Refresher.new.call
    puts "Wrote #{count} ratings for #{Fighter.count} fighters."
  end
end
