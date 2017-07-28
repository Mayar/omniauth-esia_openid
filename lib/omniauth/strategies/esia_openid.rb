require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class EsiaOpenid < OmniAuth::Strategies::OAuth2
      option :name, 'esia_openid'

      args [:client_id, :secret_crt, :secret_key]
      option :client_id, nil
      option :state, nil
      option :secret_crt, nil
      option :secret_key, nil
      option :redirect_url, nil
      option :access_type, 'online'.freeze
      option :scope, 'fullname email'.freeze
      option :client_options, {
          site: 'https://esia.gosuslugi.ru'.freeze,
          authorize_url: 'aas/oauth2/ac'.freeze,
          token_url: 'aas/oauth2/te'.freeze
      }

      def uid
        @uid ||= @payload['urn:esia:sbj_id']
      end

      info do
        prune!({
                   'name' => [raw_info['firstName'], raw_info['middleName'], raw_info['lastName']].join(' '),
                   'email' => (raw_info['EML']||{})['value'],
                   'first_name' => raw_info['firstName'],
                   'patron_name' => raw_info['middleName'],
                   'last_name' => raw_info['lastName'],
               })
      end

      extra do
        {'raw_info' => raw_info}
      end

      def client
        ::OAuth2::Client.new(options.client_id, client_secret, deep_symbolize(options.client_options))
      end

      def build_access_token
        log :debug, __method__
        access_token = client.auth_code.get_token(request.params['code'], {
            state: state,
            scope: options.scope,
            timestamp: timestamp,
            redirect_uri: callback_url,
            token_type: 'Bearer'
        })
        log :debug, 'access_token answer:'
        log :debug, "state = #{request.params['state']}"
        log :debug, "access_token = #{access_token.token}"
        log :debug, "expires_at = #{access_token.expires_at}"
        payload(access_token.token)
        access_token
      end

      def authorize_params
        super.tap do |params|
          params[:state] = state
          params[:access_type] = options.access_type
          params[:client_secret] = client_secret
          params[:timestamp] = timestamp
          session['omniauth.state'] = params[:state]
        end
      end

      def callback_call
        log :debug, "Request phase return params = #{request.params}"
        super
      end

      private
      def prune!(hash)
        hash.delete_if do |_, value|
          prune!(value) if value.is_a?(Hash)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end
      end

      def raw_info
        return @raw_info if @raw_info && !@raw_info.empty?
        @raw_info = {}

        access_token.options[:mode] = :header

        main = (access_token.get("/rs/prns/#{uid}").parsed || {})
        log :debug, "raw_info, personal info = #{main}"
        main.delete('stateFacts')
        main.delete('eTag')
        @raw_info.merge!(main)
        ctts = (access_token.get("/rs/prns/#{uid}/ctts?embed=(elements)").parsed || {})
        log :debug, "raw_info, ctts info = #{ctts}"
        ctts.fetch('elements', {}).each do |el|
          el.delete('stateFacts')
          el.delete('eTag')
          @raw_info[el.delete('type')] = el
        end
        @raw_info
      end


      def payload(token)
        unless @payload
          @payload = JWT.decode(token, nil, false)[0]
          log :debug, "payload = #@payload"
        end
        @payload
      end

      def client_secret
        return @client_secret if @client_secret
        certificate = OpenSSL::X509::Certificate.new(options.secret_crt)
        pkey = OpenSSL::PKey::RSA.new(options.secret_key)
        log :debug, "scope = #{options.scope}"
        log :debug, "timestamp = #{timestamp}"
        log :debug, "client_id = #{options.client_id}"
        log :debug, "state = #{state}"
        data = options.scope + timestamp + options.client_id + state
        signature = OpenSSL::PKCS7.sign(certificate, pkey, data, [], OpenSSL::PKCS7::DETACHED)
        @client_secret = Base64.urlsafe_encode64(signature.to_der.to_s.force_encoding('utf-8'), padding: false)
      end

      def timestamp
        @timestamp ||= DateTime.now.strftime('%Y.%m.%d %H:%M:%S %z')
      end

      def state
        @state ||= request.params['state'] || SecureRandom.uuid
      end

      def callback_url
        options.redirect_url || (full_host + script_name + callback_path)
      end
    end
  end
end