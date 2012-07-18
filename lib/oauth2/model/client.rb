module OAuth2
  module Model

    class Client < ActiveRecord::Base
      self.table_name = :oauth2_clients

      belongs_to :oauth2_client_owner, :polymorphic => true
      alias :owner  :oauth2_client_owner
      alias :owner= :oauth2_client_owner=

      has_many :authorizations, :class_name => 'OAuth2::Model::Authorization', :dependent => :destroy

      validates_uniqueness_of :client_id
      validates_presence_of   :name, :redirect_uri
      validate :check_format_of_redirect_uri

      attr_accessible :name, :redirect_uri

      before_create :generate_credentials

      def self.create_client_id
        OAuth2.generate_id do |client_id|
          count(:conditions => {:client_id => client_id}).zero?
        end
      end

      def valid_client_secret?(secret)
        secret == self.client_secret
      end

    private

      def check_format_of_redirect_uri
        redirect_uri.split("\n").each do |ruri|
          uri = URI.parse(ruri)
          errors.add(:redirect_uri, 'must contain only absolute URIs') unless uri.absolute?
        end
      rescue
        errors.add(:redirect_uri, 'must contain only URIs')
      end

      def generate_credentials
        self.client_id = self.class.create_client_id
        self.client_secret = OAuth2.random_string
      end
    end

  end
end

