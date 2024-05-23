ssh-create:
  docker exec -it keycloak openssl genrsa -out ./opt/bitnami/keycloak/certs/server.key 2048
  docker exec -it keycloak openssl req -new -x509 -key ./opt/bitnami/keycloak/certs/server.key -out ./opt/bitnami/keycloak/certs/server.pem -days 365

  # tls
  # keytool -genkey -alias "./opt/bitnami/keycloak/certs/keystore.jks" -keyalg RSA -keystore ./opt/bitnami/keycloak/certs/keystore.jks -keysize 2048
  # keytool -genkey -alias truststore -keyalg RSA -keystore ./opt/bitnami/keycloak/certs/truststore.jks -keysize 2048

  # ssl
  # keytool -genkey -alias "./regru-ssl/keystore.jks" -keyalg RSA -keystore ./regru-ssl/keystore.jks -keysize 2048
  # keytool -genkey -alias truststore -keyalg RSA -keystore ./regru-ssl/truststore.jks -keysize 2048

keycloak-logs-clear:
  docker inspect --format='{{.LogPath}}' keycloak
  sudo sh -c 'echo "" > $(docker inspect --format="{{.LogPath}}" keycloak)'