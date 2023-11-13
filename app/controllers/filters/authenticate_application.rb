module Filters
  class AuthenticateApplication
    def self.before(controller)
      Fb::Jwt::Auth.new(
        token: controller.send(:access_token),
        leeway: ENV['MAX_IAT_SKEW_SECONDS'].to_i,
        logger: Rails.logger
      ).verify!
    end
  end
end
