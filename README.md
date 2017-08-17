# OmniAuth ESIA

This is the unofficial OAuth2 Strategy for [OmniAuth](https://github.com/intridea/omniauth) authenticating to 
Russian government authentication system for persons (ESIA). 

Аутентификация с использованием OpenID Connect 1.0. 
[Методические рекомендации по использованию Единой системы идентификации и аутентификации Версия 2.23.](http://minsvyaz.ru/uploaded/presentations/esiametodicheskierekomendatsii223.pdf)
Делалось для внутренних нужд. Пользовать на свой страх и риск!

## Установка

Добавить в `Gemfile`:

```ruby
gem 'omniauth-esia_openid'
```

Сделать `bundle install`

## Пользование

```ruby
use OmniAuth::Builder do
  provider :esia_openid, ENV['ESIA_CLIENT'], File.read(ENV['ESIA_CRT_PATH']), File.read(ENV['ESIA_KEY_PATH']), {
      scope: 'openid mobile fullname email', # Только "Данные о физическом лице" и "Контактные данные"
      ctts: true, #Для получения контактов физического лица.
      client_options: { # Меняем ссылки на тестовые 
          site: 'https://esia-portal1.test.gosuslugi.ru',
          authorize_url: 'aas/oauth2/ac',
          token_url: 'aas/oauth2/te'
      }
  }
end
```
ctts == Сведения о контактах физического лица. Запрашиваются отдельным запросом. Включать только 
если у вас есть соответствующее разрешение. 
На данный момент (17.08.2017) для коммерческих организаций доступны только openid и fullname. Соответвенно: ctts: афдыу 