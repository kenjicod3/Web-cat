#include "esp_camera.h"
#include "WiFi.h"

#define CAMERA_MODEL_AI_THINKER
#include "camera_pins.h"

// Globals
String ssid = "";
String password = "";
bool connected = false;
bool streaming = false;

// Store config so we can deinit later
camera_config_t config;

// Forward declarations
void startCameraStream();
void stopCameraStream();

void setup() {
  Serial.begin(115200);
  Serial.setTimeout(2000);
  Serial.println("Waiting for Wi-Fi credentials...");
}

void loop() {
  if (!connected) {
    // === Wait for SSID ===
    Serial.println("🔹 Enter SSID:");
    while (Serial.available() == 0) delay(100);
    ssid = Serial.readStringUntil('\n');
    ssid.trim();

    // === Wait for Password ===
    Serial.println("🔹 Enter Password:");
    while (Serial.available() == 0) delay(100);
    password = Serial.readStringUntil('\n');
    password.trim();

    // === Connect Wi-Fi ===
    Serial.println("📲 Connecting to Wi-Fi...");
    WiFi.begin(ssid.c_str(), password.c_str());

    int retries = 0;
    while (WiFi.status() != WL_CONNECTED && retries < 20) {
      delay(500);
      Serial.print(".");
      retries++;
    }

    if (WiFi.status() == WL_CONNECTED) {
      connected = true;
      Serial.println("\nWi-Fi Connected: " + WiFi.localIP().toString());
      Serial.println("💡 Waiting for 'start' command...");
    } else {
      Serial.println("\nWi-Fi connection failed.");
    }
  }

  // === Listen for 'start' or 'stop' commands ===
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();

    if (cmd == "start" && !streaming) {
      startCameraStream();
    }
    else if (cmd == "stop" && streaming) {
      stopCameraStream();
    }
  }

  delay(100);
}

void startCameraStream() {
  // === Camera config ===
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;

  if (psramFound()) {
    config.frame_size = FRAMESIZE_VGA;
    config.jpeg_quality = 10;
    config.fb_count = 2;
  } else {
    config.frame_size = FRAMESIZE_CIF;
    config.jpeg_quality = 12;
    config.fb_count = 1;
  }

  if (esp_camera_init(&config) != ESP_OK) {
    Serial.println("Camera init failed");
    return;
  }

  startCameraServer(); // from app_httpd.cpp
  streaming = true;
  Serial.println("Camera stream started!");
  Serial.println("Stream at: http://" + WiFi.localIP().toString() + ":81/stream");
}

void stopCameraStream() {
  esp_camera_deinit();
  streaming = false;
  Serial.println("Camera stream stopped.");
}
