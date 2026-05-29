# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def welcome_email(user)
    @user = user
    mail(to: @user.email, subject: "Welcome to the platform!")

  def notification_email(notification)
    @notification = notification
    @user = notification.recipient
    mail(to: @user.email, subject: @notification.message)
  end
end

  def notification_email(notification)
    @notification = notification
    @user = notification.recipient
    mail(to: @user.email, subject: @notification.message)
  end
end
