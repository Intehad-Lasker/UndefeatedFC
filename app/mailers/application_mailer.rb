class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "UndefeatedFC <no-reply@example.com>")
  layout "mailer"
end
