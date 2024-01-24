class EmailController < ApplicationController
  # example json payload:
  #
  # {
  #   message: {
  #     to: 'user@example.com',
  #     subject: 'subject goes here',
  #     body: 'body as string goes here',
  #     template_name: 'name-of-template',
  #     [extra_personalisation]: {
  #       token: 'my-token'
  #     }
  #   }
  # }
  #
  def create
    return render_errors unless email_validator.valid?

    render json: {}, status: :created if job_class.perform_later(message: message_params)
  end

  private

  def email_validator
    Email.new(message_params)
  end

  def render_errors
    render json: { name: 'bad-request.invalid-parameters' }, status: :bad_request
  end

  def message_params
    params.require(:message).permit(:to, :subject, :body, :template_name, extra_personalisation: [:token])
  end

  def job_class
    EmailJob
  end
end
