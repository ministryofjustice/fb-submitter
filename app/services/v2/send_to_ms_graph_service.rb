require 'cgi'

module V2
  class SendToMsGraphService
    attr_accessor :site_id, :list_id, :drive_id, :root_graph_url, :reference_number, :service_slug

    def initialize(action, service_slug)
      @root_graph_url = action['graph_url']
      @site_id = action['site_id']
      @list_id = action['list_id']
      @drive_id = action['drive_id']
      @reference_number = action['reference_number']
      @service_slug = service_slug
    end

    def post_to_ms_list(submission, id)
      uri = URI.parse("#{root_graph_url}/sites/#{site_id}/lists/#{list_id}/items")

      @connection ||= Faraday.new(uri) do |conn|
      end

      answers_payload = ms_list_payload(submission, id)

      response = @connection.post do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{get_auth_token}"
        req.body = { 'fields' => answers_payload }.to_json
      end

      Sentry.capture_message("#{response.status} from MS API for #{service_slug}, error: #{response.body}") unless response.success?

      JSON.parse(response.body)
    end

    def create_folder_in_drive(submission_id)
      drive_name = CGI.escape("#{submission_id}-attachments")

      uri = URI.parse("#{root_graph_url}/sites/#{site_id}/drive/items/#{drive_id}/children")

      connection ||= Faraday.new(uri) do |conn|
      end

      body = {
        'name' => drive_name,
        'folder' => {}
      }

      response = connection.post do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{get_auth_token}"
        req.body = body.to_json
      end

      if response.status == 201
        JSON.parse(response.body)['id']
      else
        Sentry.capture_message("#{response.status} from MS API for #{service_slug}, error: #{response.body}") unless response.success?
        drive_id
      end
    end

    def send_attachment_to_drive(attachment, _id, folder)
      filename = CGI.escape(attachment.filename)
      uri = URI.parse("#{root_graph_url}sites/#{site_id}/drive/items/#{folder}:/#{filename}:/content")

      connection = Faraday.new(uri) do |conn|
      end

      response = connection.put do |req|
        req.headers['Content-Type'] = 'text/plain'
        req.headers['Authorization'] = "Bearer #{get_auth_token}"
        req.body = File.read(attachment.path)
      end

      Sentry.capture_message("#{response.status} from MS API for #{service_slug}, error: #{response.body}") unless response.success?

      JSON.parse(response.body)
    end

    def get_auth_token
      response = auth_connection.post do |req|
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.body = URI.encode_www_form(form_data)
      end

      response_body = JSON.parse(response.body)

      response_body['access_token']
    end

    def ms_list_payload(submission, id)
      new_data = {
        'fields' => {
          Digest::MD5.hexdigest('Submission ID').tr('0-9', '') => id,
          Digest::MD5.hexdigest('Reference Number').tr('0-9', '') => @reference_number
        }
      }

      merge_data = []

      submission['pages'].each do |page|
        page['answers'].each do |answer|
          value = answer['answer'].is_a?(Hash) ? answer_from_hash(answer) : answer['answer']
          keystring = answer['field_id'].to_s
          colname = Digest::MD5.hexdigest(keystring).tr('0-9', '')
          merge_data << { colname => value }
        end
      end

      result_hash = {}

      merge_data.each do |hash|
        result_hash.merge!(hash)
      end

      new_data['fields'].merge!(result_hash)
    end

    def answer_from_hash(answer)
      answer.map { |_k, v| v }.join('; ')
    end

    private

    def auth_connection
      @auth_connection ||= Faraday.new(URI.parse(auth_url)) do |conn|
        conn.response :raise_error
        conn.adapter :net_http
      end
    end

    def form_data
      {
        client_id: admin_app,
        client_secret: admin_secret,
        grant_type: 'client_credentials',
        resource: 'https://graph.microsoft.com/'
      }
    end

    def admin_app
      ENV['MS_ADMIN_APP_ID']
    end

    def admin_secret
      ENV['MS_ADMIN_APP_SECRET']
    end

    def auth_url
      ENV['MS_OAUTH_URL']
    end
  end
end
