module Laeron
  module Validator
    INVALID_USERNAME_SEQUENCE = /-'|''|'_/
    class << self
      def valid_username?(username)
        if username =~ Laeron.config.login.valid_username
          if username.scan(/'/).count <= 2 && username.scan(/-/).count <= 1
            return username.scan(Validator::INVALID_USERNAME_SEQUENCE).count == 0
          end
        end
        false
      end

      def valid_password?(password)
        password =~ Laeron.config.login.valid_password
      end
    end
  end
end