require 'base64'

module OAuth2
  class Router

    # Public methods in the namespace take either Rack env objects, or Request
    # objects from Rails/Sinatra and an optional params hash which it then
    # coerces to Rack requests. This is for backward compatibility; originally
    # it only took request objects.

    class << self
      def parse(resource_owner, env)
        error   = detect_transport_error(env)
        request = request_from(env)
        params  = request.params
        auth    = auth_params(env)

        if auth[CLIENT_ID] and auth[CLIENT_ID] != params[CLIENT_ID]
          error ||= Provider::Error.new("#{CLIENT_ID} from Basic Auth and request body do not match")
        end

        params = params.merge(auth)

        if params[GRANT_TYPE]
          error ||= Provider::Error.new('must be a POST request') unless request.post?
          Provider::Exchange.new(resource_owner, params, error)
        else
          Provider::Authorization.new(resource_owner, params, error)
        end
      end

      def access_token(resource_owner, scopes, env)
        access_token = access_token_from_request(env)
        Provider::AccessToken.new(resource_owner,
                                  scopes,
                                  access_token,
                                  detect_transport_error(env))
      end

      def access_token_from_request(env)
        request = request_from(env)
        params  = request.params
        header  = request.env['HTTP_AUTHORIZATION']

        puts params.inspect

        header && header =~ /^OAuth\s+/ ?
            header.gsub(/^OAuth\s+/, '') :
            params[OAUTH_TOKEN]
      end

    private

      def request_from(env_or_request)
        env = env_or_request.respond_to?(:env) ? env_or_request.env : env_or_request
        env = Rack::MockRequest.env_for(env['REQUEST_URI'] || '', :input => env['RAW_POST_DATA']).merge(env)
        Rack::Request.new(parse_json_params(env))
      end

      #FIXME This is a hack so Rack requests can parse raw JSON POSTs. It preps the env hash to trick Rack::Request.POST
      #      into accepting our parsed JSON params --- Probably a much cleaner way to handle this.
      def parse_json_params(env)
        if env['rack.input'] && !env['rack.request.form_input'].eql?(env['rack.input']) && env['CONTENT_TYPE'] && env['CONTENT_TYPE'].split(/\s*[;,]\s*/, 2).first.downcase == 'application/json'
          env['rack.request.form_input'] = env['rack.input']
          data = env['rack.input'].read
          env['rack.input'].rewind
          env['rack.request.form_hash'] = data.empty? ? {} : JSON.parse(data)
        end
        env
      end

      def auth_params(env)
        return {} unless basic = env['HTTP_AUTHORIZATION']
        parts = basic.split(/\s+/)
        username, password = Base64.decode64(parts.last).split(':')
        {CLIENT_ID => username, CLIENT_SECRET => password}
      end

      def detect_transport_error(env)
        request = request_from(env)

        if Provider.enforce_ssl and not request.ssl?
          Provider::Error.new("must make requests using HTTPS")
        end
      end
    end

  end
end

