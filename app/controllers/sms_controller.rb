class SmsController < ApplicationController
  # example json payload:
  #
  # {
  #   message: {
  #     to: '07123456789',
  #     body: 'body as string goes here',
  #     template_name: 'name-of-template',
  #     [extra_personalisation]: {
  #       token: 'my-token'
  #     }
  #   }
  # }
  #
  def create
    return render_errors unless sms_validator.valid?

    render json: {}, status: :created if job_class.perform_later(message: message_params)
  end

  private

  def sms_validator
    Sms.new(message_params)
  end

  def render_errors
    render json: { name: 'bad-request.invalid-parameters' }, status: :bad_request
  end

  def message_params
    params.require(:message).permit(:to,
                                    :body,
                                    :template_name,
                                    extra_personalisation: [:code])
  end

  def job_class
    SmsJob
  end
end
