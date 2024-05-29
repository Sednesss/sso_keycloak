# Настройка Client

**Client** в **Keycloak** представляет из себя аккаунт для (frontend или backend) приложения, из которого будут поступать запросы на авторизацию пользователя в систему "глобально". 

Пример SSO Keycloak с двумя **Client**: 
1) Когда пользователь хочет авторизоваться через **Client 1**, то **Client 1** перенаправляет пользователя в **Keycloak**, где после ввода учетных данных браузер пользователя сохраняет сеанс пользователя в coockie на домене **Keycloak** и пользователь перенаправляется обратно в **Client 1** вместе с данными авторизации [`code` - по которому можно получить `access_token`, в котором содержится информация о пользователе].  

2) Когда пользователь хочет авторизоваться с этого же устройства с этого же браузер на **Client 2**, то **Client 2** перенаправляет пользователя в **Keycloak**, где **Keycloak** проанализируя cookie, поймёт, что пользователь уже имеет акивную сессию и перенаправит пользователя обратно в **Client 2** вместе с данными авторизации [`code` - по которому можно получить `access_token`, в котором содержится информация о пользователе].

**Keycloak** позволяет настраивать авторизацию между **Keycloak** и **Client** через:
- Keycloak Open ID Connect
- Open ID Connect v1.0
- SAML v2.0

:exclamation:Выбранным стандартом является **Keycloak Open ID Connect** и производимые настройки относятся только к нему. [Подробнее тут](https://www.keycloak.org/docs/latest/securing_apps/#_oidc)

*(По умолчанию **Keycloak** разрешает подключать **Celient's** к **Keycloak** с помощью  ODIC и SAML. При необходимости можно выбрать и настроить другой вариант вариант авторищации между **Keycloak** и **Client** можно на соответсвующей странице "Identity Providers")*

![alt text](<img/README-client/image-1.png>)

## Требования к приложению

Приложение, через которое предполагается, что пользователь сможет авторизовываться глобально (сразу в нескольких приложенях) должно функционировать и быть расположено по общедоступному адресу.

**Keycloak** предлагает использовать [клиентскую библиотеку JavaScript](https://www.keycloak.org/docs/latest/securing_apps/#_javascript_adapter), для правильного формирования запросов в **Keycloak**:
*(Запросы можно формировать самостоятельно, но лучше пользоваться библиотекой)*
```sh
npm install keycloak-js
```

Информацию о конфигурации Keycloak ODIC можно получить в разделе: **Realm Settings --> Endpoints** или обратившись по маршруту `<keycloak-domain>/realms/demo-area/.well-known/openid-configuration` [Подробнее](https://www.keycloak.org/docs/latest/securing_apps/#available-endpoints): 

![alt text](<img/README-client/image-2.png>)

## Создание и настройка в Keycloak

Создание аккаунта для **Client** находится на соответсвующей странице:

![alt text](<img/README-client/image-3.png>)

При **Client** создании ему необходимо задать определённые свойства, определяющие его. На скриншотах ниже представлен пример создания **Client** для моего приложения, которое располагается по url: `https://626c-171-33-248-67.ngrok-free.app`: *(При необходимости заданные свойства могут быть изменены позже, кроме свойства **"Client type"** в разделе **"General settings"**)*.

![alt text](<img/README-client/image-4.png>) 
![alt text](<img/README-client/image-5.png>)
![alt text](<img/README-client/image-6.png>) 

*(При наведении на свойство выводится подробное описание того, за что отвечает свойство)*

В разделе **"Login settings"** мы задали url приложения и разрешённые маршруты переадресации, на которые будет перенаправляться пользователь при "глобальной" авторизации или завершении сеанса авторизации.

Далее на странице настроек клиента нам необходимо настроить маршрут для выхода через обратный канал **Clients-->[client-id]-->Settings-->Logout Settings**.
*(Если у нас будет 2 приложения в которых пользователь авторизован **Client 1** и **Client 2**, то при выходе из **Client 1**, то **Keycloak** отправит уведомление в **Client 2** на настраиваемый маршрут о том, что сеанс авторизации для данного пользователя был у завершён, чтобы **Client 2** удалил данные об авторизации для данного пользователя)*.

![alt text](<img/README-client/image-7.png>)

*(При включенной настройке "Front channel logout", в обратный канал ничего не будет приходить, поэтому эту настройку следует отключить).*

`secret_key` для **Client** можно получить/изменить в разделе **Clients-->[client-id]-->Credentials**.

Данных настроек достаточно, чтобы связать приложение с **Keycloak**.

## Привязка приложения к Keycloak

В приложении должны быть установлены маршруты/функционал (удобнее строить маршруты/функционал через [клиентскую библиотеку JavaScript](https://www.keycloak.org/docs/latest/securing_apps/#_javascript_adapter)):

- (функционал для перенаправления на авторизацию в **Keycloak**) - когда пользователь нажимает на кнопку "авторизоваться", то приложение перенаправляет пользователя в **Keyckloak** с необходимыми query param на маршрут:
GET `<keycloak-domain>/realms/<realm>/protocol/openid-connect/auth`:
    - client_id: `<client-id>`
    - redirect_uri: `<app-domain>/keycloak/auth-callback`
    - scope: `openid`
    - response_type: `code`
    - state: `<generated-state>`

- `/keycloak/auth-callback` (маршрут для приёма авторизации от **Keycloak**) - когда пользователь вводит верные учётные данные в **Keycloak** или если он уже имеет активный сеанс авторизации через другой зарегестрированные **Client**, то его перенаправляет на этот маршрут с необходимыми query param:
    - state: `<generated-state>` - можем проверить ответ
    - session_state: `<session-state>`
    - iss: `<keycloak-domain>/realms/<realm>` - можем проверить ответ
    - code: `<auth-code>` - понадобится, чтобы получить токен

- (функционал для получения **`access_token`** от **Keycloak**) - Когда пользователь авторизовался и наше приложение получило `<auth-code>`, то мы можем отправить запрос на получение **`access_token`** в этот же **Realm**:
POST `<keycloak-domain>/realms/<realm>/protocol/openid-connect/token`:
    - code: `<auth-code>`
    - client_id: `<client-id>`
    - client_secret: `<client-secret>`
    - grant_type: `authorization_code`
    - redirect_uri : `<app-domain>/keycloak/auth-callback`

    В ответе будет находиться информация о сенансе авторизации и `access_token`, `refresh_token`, `token_id`.

    

- Если время жизни `access_token` истекло, то можем получить новый токен используя `refresh_token`:
POST `<keycloak-domain>/realms/<realm>/protocol/openid-connect/token`:
    - client_id: `<client-id>`
    - client_secret: `<client-secret>`
    - grant_type: `refresh_token`
    - refresh_token : `<refresh-token>`

   *(Время жизни токена по умолчанию равно 5 минут = 300 секунд, его можно изменить как для **Realm** в разделе **"Realm Settings --> Tokens"**, так и для отдельного **Client** в разделе **"Clients --> <client-id> --> Advanced --> Advanced settings"**).*

- Чтобы получить информацию о авторизованном пользователе (`name`, `email`, `sub` - user-id и т.д.) необходимо направлять запросы на соответсвующий маршрут в **Keycloak** c заголовками:
    POST `<keycloak-domain>/realms/<realm>/protocol/openid-connect/userinfo`:
    - Authorization: **`<access_token>`**
    - Content-Type: `application/x-www-form-urlencoded`

- (функционал для перенаправления на завершение сенса авторизации в **Keycloak**) - когда пользователь нажимает на кнопку "выйти", то приложение перенаправляет пользователя в **Keyckloak** с необходимыми query param на маршрут:
    GET `<keycloak-domain>/realms/<realm>/protocol/openid-connect/logout`
    - client_id: `<client-id>`
    - post_logout_redirect_uri: `<app-domain>`
    - id_token_hint: `<token_id>`

- `/keycloak/backchannel-logout` (маршрут для уведомления о завершении пользовательского сеанса авторизации от **Keycloak** (отправляется только в те **Client**, в которых был осуществлён вход и в которых настроен backchannel logout в интерфейсе admin panel **Keycloak**)) - когда пользователь выходит из другого **Client** в этом же **Realm**, то 
текущий **Client** получает на этот маршрут запрос от **Keycloak**, о том, что был произведён logout данного пользователя (необходимо очистить данные о авторизации для данного пользователя в браузере).

- (Необязательно) Чтобы проверить, что `access-token` еще активен, можно отправить запрос на соответсвующий маршрут в **Keycloak**, в итоге получим либо `false`, либо `true` с декодированным содержимым `access-token`:
    POST `<keycloak-domain>/realms/<realm>/protocol/openid-connect/token/introspect`
    - client_id: `<client-id>`
    - client_secret: `<client-secret>`
    - token: `<access-token>`

Когда у приложения есть `access-token`, то можно отправлять запросы в **Backend**, авторизуя запросы в заголовке `Authorization` с префиксом 'Bearer'.

***(TODO: отправлять токен на определённый маршрут в Backend, для обновления пользовательских данных в локальной БД Backend)***