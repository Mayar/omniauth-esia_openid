require File.expand_path('../lib/omniauth-esia_openid/version', __FILE__)

Gem::Specification.new do |s|
  s.name     = 'omniauth-esia_openid'
  s.authors  = ['Dmitry Martsinovsky']
  s.version  = OmniAuth::EsiaOpenid::VERSION
  s.email    = ['mayar@yandex.ru']
  s.summary  = 'OAuth2 Strategy for ESIA over OpenID Connect 1.0'
  s.homepage = 'https://github.com/mayar/omniauth-esia_openid'

  s.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'omniauth-oauth2', '~> 1.4'
end
