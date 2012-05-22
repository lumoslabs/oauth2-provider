module OAuth2
  module Model

    module ResourceOwner
      def self.included(klass)
        klass.has_many :oauth2_authorizations,
                       :class_name => 'OAuth2::Model::Authorization',
                       :as => :oauth2_resource_owner,
                       :dependent => :destroy
      end

      def grant_access!(client, options = {})
        authorization = oauth2_authorizations.find_by_client_id(client.id) unless options[:force_new]
        authorization ||= Model::Authorization.new(:owner => self, :client => client)

        authorization.scope = (authorization.scopes + options[:scopes]).entries.join(' ') if options[:scopes]
        authorization.expires_at = Time.now + options[:duration].to_i if options[:duration]

        authorization.save
        authorization
      end
    end

  end
end
