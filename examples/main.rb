require 'sinatra'
require 'omniauth'
require 'omniauth-esia_openid'

configure {set :server, :puma}

use Rack::Session::Cookie

use OmniAuth::Builder do
  provider :esia_openid, ENV['ESIA_CLIENT'], File.read(ENV['ESIA_CRT']), File.read(ENV['ESIA_KEY']), {
      scope: 'email fullname',
      client_options: {
          site: 'https://esia-portal1.test.gosuslugi.ru'.freeze,
          authorize_url: 'aas/oauth2/ac'.freeze,
          token_url: 'aas/oauth2/te'.freeze
      }
  }
end

get '/' do
  <<-HTML
    <a href='/auth/esia_openid'>ЕСИА</a>
  HTML
end

get '/auth/:provider/callback' do
  content_type 'text/plain'
  puts request.env['omniauth.auth']
  request.env['omniauth.auth'].to_hash.inspect
end
