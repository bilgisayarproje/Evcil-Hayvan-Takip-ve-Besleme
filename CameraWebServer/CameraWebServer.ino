
#include <WiFi.h>
#include <WebSocketsServer.h>
#include "CameraWebServer.h"

const char* ssid = "********";
const char* password = "*******";
const int webSocketPort = 8080;

WebSocketsServer webSocket = WebSocketsServer(webSocketPort);
CameraWebServer cameraServer(80);

void setup() {
  Serial.begin(115200);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("WiFi connected");

  cameraServer.begin();
  webSocket.begin();
  webSocket.onEvent(webSocketEvent);
}

void loop() {
  cameraServer.handleClient();
  webSocket.loop();
}

void webSocketEvent(uint8_t num, WStype_t type, uint8_t *payload, size_t length) {
  switch (type) {
    case WStype_DISCONNECTED:
      Serial.printf("[%u] Disconnected!\n", num);
      break;
    case WStype_CONNECTED:
      {
        IPAddress ip = webSocket.remoteIP(num);
        Serial.printf("[%u] Connected from %d.%d.%d.%d url: %s\n", num, ip[0], ip[1], ip[2], ip[3], payload);
      }
      break;
    default:
      break;
  }
}