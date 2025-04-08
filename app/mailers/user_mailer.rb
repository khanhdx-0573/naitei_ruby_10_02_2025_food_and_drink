class UserMailer < Devise::Mailer
  helper :application
  include Devise::Controllers::UrlHelpers
  default from: ENV["MAIL_SENDER"]

  def confirmation_instructions record, token, _opts = {}
    @token = token
    @resource = record
    @email = record.email

    mail(
      to: @email,
      subject: I18n.t("devise.mailer.confirmation_instructions.subject"),
      template_path: "devise/mailer",
      template_name: "confirmation_instructions"
    )
  end

  def reset_password_instructions record, token, _opts = {}
    @token = token
    @resource = record
    @email = record.email

    mail(
      to: @email,
      subject: I18n.t("devise.mailer.reset_password_instructions.subject"),
      template_path: "devise/mailer",
      template_name: "reset_password_instructions"
    )
  end
end
