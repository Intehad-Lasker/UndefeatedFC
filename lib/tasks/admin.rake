namespace :admin do
  desc "Make an existing account an admin: bin/rails admin:grant[someone@example.com]"
  task :grant, [ :email_address ] => :environment do |_, args|
    user = User.find_by!(email_address: args.fetch(:email_address).strip.downcase)
    user.update!(admin: true)
    puts "#{user.display_name} is now an admin."
  end
end
