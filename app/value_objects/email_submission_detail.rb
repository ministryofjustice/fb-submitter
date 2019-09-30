class EmailSubmissionDetail
  include ActiveModel

  attr_accessor :from, :to, :subject, :body_parts, :attachments, :submission

  def initialize(params = {})
    symbol_params = params.symbolize_keys!
    @submission   = symbol_params[:submission]
    @attachments  = symbol_params[:attachments]
    @body_parts   = symbol_params[:body_parts] || []
    @from         = symbol_params[:from]
    @subject      = symbol_params[:subject]
    @to           = symbol_params[:to]

    make_urls_absolute!
  end

  def make_urls_absolute!
    attachments.each { |h| h['url'] = url_resolver.ensure_absolute_url(h['url']) if h['type'] == 'output' }

    @body_parts.each do |content_type, url|
      @body_parts[content_type] = url_resolver.ensure_absolute_url(url)
    end
  end

  def url_resolver(submission: @submission, environment_slug: ENV['FB_ENVIRONMENT_SLUG'])
    @url_resolver ||= Adapters::ServiceUrlResolver.new(
      service_slug: submission.service_slug,
      environment_slug: environment_slug
    )
  end
end
