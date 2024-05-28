# Keycloak-SSO

*(Текущая версия без reverse proxy)*

Внедрение простого SSO с минимальными требованиями:
- Единая точка входа для разных ресурсов
- Централизованная аутентификация и авторизация
- Ограничение прав пользователей по отношению к **Client**/по отношению к **Realm**

Основные понятия:
- **Client (Keycloak)** - пользовательское приложение, через которое пользователь может аутентифицироваться/авторизоваться в **Realm**
- **Realm (Keycloak)** - Объединение группы **Client's** и группы пользователей, в которой авторизованному пользователю выдаются права по отношению к **Client**/по отношению к **Realm**
- (Пользователь аутентифицируется/авторизуется через какой либо UI "frontend/backend" приожение **Client** после чего **Realm** хранит его авторизацию (**Realm** узнает пользователя если он попробует авторизоваться через другое приложение **Client 2** и авторизует его в **Client 2**, если у пользователя существует активынй сеанс в **Realm**))

Полезные ресурсы:
- Keycloak docs: [here](https://www.keycloak.org/documentation)
- bitnami/keycloak docs: [here](https://hub.docker.com/r/bitnami/keycloak)

## Содержание
- [Необходимое ПО](#необходимое-по)
- [Начало работы](#начало-работы)
- [Использование Keycloak](#использование-keycloak)
<!-- - [Тестирование](#тестирование)
- [Deploy и CI/CD](#deploy-и-ci/cd)
- [Contributing](#contributing)
- [To do](#to-do)
- [Команда проекта](#команда-проекта) -->

## Необходимое ПО
- [Docker](https://docs.docker.com/engine/install/ubuntu/)
```sh
### for Ubuntu 24.04 ###

sudo apt update
sudo apt install ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

- [Docker Compose](https://docs.docker.com/compose/)
```sh
### for Ubuntu 24.04 ###

sudo apt install docker-compose
```
- [Java Development Kit (JDK)](https://www.oracle.com/java/technologies/downloads/)

```sh
### for Ubuntu 24.04 ###

apt search openjdk

### select from the list and install ###
### example for my system: ###

sudo apt install openjdk-8-jdk-headless
```

## Начало работы

*(Необходимо иметь зарегистрированный домен и дейсвительный tls/ssl сертефикат)*

В docker-compose.yml описаны инструкции для разворачивания минимального жизнеспособного keycloak с поддержкой https **(без reverse proxy)**

### Файлы хранилища ключей и доверенных сертификатов

Файлы могут быть сгенерированны с помощью утилиты **Java Development Kit (JDK)**:
```sh
keytool -genkey -alias "./deploy/keycloak/http-store/keystore.jks" -keyalg RSA -keystore ./deploy/keycloak/http-store/keystore.jks -keysize 2048
keytool -genkey -alias truststore -keyalg RSA -keystore ./deploy/keycloak/http-store/truststore.jks -keysize 2048
```

### Инициализация переменных окружения

```sh
cp .env.example .env
```

:grey_question:При необхдимости можно изменить доступы к БД на свои:
```sh
# .env
KEYCLOAK_DB_TYPE=postgresql
KEYCLOAK_DB_NAME=keycloakdb
KEYCLOAK_DB_USER=keycloakdbuser
KEYCLOAK_DB_PASSWORD=EqhvLbsPhrkkZjcaGWcV7qT
```

:grey_question:При необхдимости можно изменить доступы к учётной записи администратора (для WEB UI Keycloak и другие **Client's** установленные по умолчанию):
```sh
# .env
KEYCLOAK_ADMIN_USERNAME=admin
KEYCLOAK_ADMIN_PASSWORD=rwXPqspCABJzqh47i723wf9
```

:exclamation:Необходимо указать зарегестрированный домен:
```sh
# .env
KEYCLOAK_HOSTNAME=<your-domain>
```

:exclamation:Необходимо указать названия [сгенерированных файлов](#файлы-хранилища-ключей-и-доверенных-сертификатов) хранилища ключей и доверенных сертификатов и указанный при их создании пароль:
*(файлы должны быть расположены по пути `./deploy/keycloak/http-store`)*
```sh
# .env
KEYCLOAK_HTTPS_KEY_STORE_FILENAME=keystore.jks
KEYCLOAK_HTTPS_TRUST_STORE_FILENAME=truststore.jks
KEYCLOAK_HTTPS_KEY_STORE_PASSWORD=123456
KEYCLOAK_HTTPS_TRUST_STORE_PASSWORD=123456
```

:exclamation:Необходимо указать названия файлов сертефиката:
*(файлы должны быть расположены по пути `./deploy/keycloak/<'cert-type'>/certificate`, где <'cert-type'> - `ssl` или `tls`)*
```sh
# .env
KEYCLOAK_HTTPS_CERTIFICATE_FILENAME=sedunova-pavel-sso-keycloak.crt
KEYCLOAK_HTTPS_CERTIFICATE_KEY_FILENAME=sedunova-pavel-sso-keycloak.key
KEYCLOAK_HTTPS_STORE_TYPE=ssl # <cert-type>
```

### Сборка и запуск

Команда для сборки и запуска:
```sh
docker-compose up -d --build
```

Наблюдение за логами контейнера с keycloak:
*(Мониторинг ошибок при неудачном запуске)*
```sh
docker logs keycloak -f
```

При необходимости можно очистить файл логов keycloak (логи контейнера автоматически очищаются при повторном его запуске):
```sh
docker inspect --format='{{.LogPath}}' keycloak
sudo sh -c 'echo "" > $(docker inspect --format="{{.LogPath}}" keycloak)'
```

При успешном запуске **Keycloak** admin panel будет доступна по указанному в `.env` **KEYCLOAK_HOSTNAME**.

Доступ к аккаунту администратора может быть осуществлён при использовании параметром из `.env`: **KEYCLOAK_ADMIN_USERNAME** и **KEYCLOAK_ADMIN_PASSWORD**.

## Использование Keycloak

- [Вариант использования](./docs/README-usage.md)
- [Настройка Realm](./docs/README-realm.md)
- [Настройка Client](./docs/README-client.md)
- [Настройка Backend для Client](./docs/README-client-resource.md)
- [Настройка User](./docs/README-user.md)
- [Настройка Role](./docs/README-role.md)
