module OAuth2
  module Model

    class Provider < ActiveRecord::Base
      include ResourceOwner
      self.table_name = :oauth2_providers

      def self.instance
        first || create(:name => 'Provider')
      end
    end
  end
end
