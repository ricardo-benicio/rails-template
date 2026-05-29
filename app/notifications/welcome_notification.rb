# frozen_string_literal: true

class WelcomeNotification < Noticed::Event
  deliver_by :database
  deliver_by :email,
    mailer: "UserMailer",
    method: :notification_email,
    delay: 5.minutes

  def message
    "Welcome, #{recipient.first_name}! Your account is confirmed."
  end
end
