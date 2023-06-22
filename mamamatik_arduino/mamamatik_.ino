#include <ThingSpeak.h> //bulut tabanlı iot platformu kütüphanesi
#include <SoftwareSerial.h> //yazılım tabanlı seri iletişim bağlantısı kütüphanesi
#include <ArduinoJson.h> //json verilerini işlemek ve oluşturma kütüphanesi
#include "HX711.h" //Ağırlık sensörü kütüphanesi

String agAdi = "******"; //Wifi adını girdiğimiz değişken
String agSifresi = "*******";  //Wifi şifresini girdiğimiz değişken
String field3; // Thingspeak ten manuel besleme yapabilmek için aldığımız field3 değişkeni

String ip = "184.106.153.149"; //Thingspeak İp adresi

//Wifi Modulü pin bağlantıları
int rxPin = 11; // modülün veri alacağı pin
int txPin = 10; //modülün veri göndereceği pin

SoftwareSerial esp(rxPin, txPin);

//Step motor pinleri
#define dirPin 3 //Step motor dir pini-yön
#define stepPin 2 //Step motor step pini
#define steptur 50 //Kaç tur atacağını belirleyen değişken

//Ağırlık sensörü değişkenlerini tanımlıyoruz.
#define LOADCELL_DOUT_PIN  5 //Ağırlık sensöründen veri alınan pin
#define LOADCELL_SCK_PIN  4 // serial clock
HX711 scale;

float kalibrasyon_faktor = 700;
float birim,kg;

//Mesafe sensör değişkenleri
const int trigger_pin = 6; // 6. pini trigger pin olarak tanımlıyoruz.
const int echo_pin = 7; // 7. pini echo pin olarak tanımlıyoruz.
long sure, mesafe;

void setup() {
  Serial.begin(9600);
  wifi();

  // Ağırlık sensörü çıkışlarını tanımlıyoruz
  scale.begin(LOADCELL_DOUT_PIN, LOADCELL_SCK_PIN);
  scale.set_scale(kalibrasyon_faktor); // Kalibrasyon faktörü tanımlama
  scale.tare(); // Ölçeği sıfırlama

  long zero_factor = scale.read_average(); //Ağırlık sensöründen bir dizi okuma yapar ve ortalamasını döndürür.
  Serial.print("Zero factor: "); 
  Serial.println(zero_factor);

  // Step Motor çıkışlarını tanımlıyoruz
  pinMode(stepPin, OUTPUT);
  pinMode(dirPin, OUTPUT);

  // Mesafe sensörü çıkışlarını tanımlıyoruz.
  pinMode(trigger_pin , OUTPUT); //trigger pin'i çıkış olarak tanımladık.
  pinMode(echo_pin , INPUT); //echo pin'i giriş olarak tanımladık.
}

void loop() 
  {
  esp.println("AT+CIPSTART=\"TCP\",\"" + ip + "\",80");
  if (esp.find("Error")) {
    Serial.println("AT+CIPSTART Error");
  }
  //Mesafe sensörü HC-SR04 ile mesafe ölçümü
  digitalWrite(trigger_pin, LOW);
  delayMicroseconds(3);
  digitalWrite(trigger_pin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigger_pin, LOW);
  sure = pulseIn(echo_pin, HIGH);
  mesafe = (sure/2) * 0.0343;
  Serial.print(mesafe);
  Serial.println(" cm uzaklıkta");
  delay(1000);
  

  //Ağırlık sensör kodları
  scale.set_scale(kalibrasyon_faktor); 
  birim = scale.get_units(),10;
  kg=(birim*10)-240;

  if (kg<0){
  kg=0;
  }

  if(kg>600){
  kg=600;
  }
  Serial.print(kg);
  Serial.print(" gram"); 
  Serial.println();
  

  if (kg<80){// Eğer mama kabındaki ağırlık sensörü 80 gramın in altında ise motoru önce saat yönünde daha sonra tersine döndürür. 
  otomatikbesleme();
 }

 verigonder();
  
    String json = getJSON();//getjson fonksiyonundan alınan json verilerini ayrıştırıp içindeki verilere erişmmek için doc nesnesini kullanıyoruz
  if (json != "") {
    // JSON verilerini ayrıştır
    DynamicJsonDocument doc(1024);
    deserializeJson(doc, json);

    // Field3 değerini oku
    String field3 = doc["feeds"][0]["field3"];//feeds dizisi içindeki ilk ögenin field3 değerinin alınıp field3 değişkenine atanması
    Serial.println("field3:"+field3);
    // Değeri seri monitöre yazdır
    if (field3=="1"){ //Eğer Thingspeakteki field3 verisi 1 e eşitse motoru çalıştırır
    manuelbesleme();
  }
  }  
  

}

void verigonder(){

  String gonderilenveri = "GET https://api.thingspeak.com/update?api_key=your API KEY";   //Thingspeak veri gönderimi. Key kısmına kendi api keyimizi yazıyoruz.                  
  gonderilenveri += "&field1="; 
  gonderilenveri += String(mesafe); //Thingspeak teki field1 alanına mesafe verisini ekliyoruz
  gonderilenveri += "&field2=";
  gonderilenveri += String(kg);  //Thingspeak teki field2 alanına kg verisini ekliyoruz
  gonderilenveri += "\r\n\r\n"; 

  esp.print("AT+CIPSEND="); //ESP'ye göndereceğimiz veri uzunluğunu veriyoruz.
  esp.println(gonderilenveri.length()+2);
  delay(3000);

  if(esp.find(">")){ //ESP8266 hazır olduğunda içindeki komutlar çalışıyor.
    esp.print(gonderilenveri); //Veriyi gönderiyoruz.
    Serial.println(gonderilenveri); //Gönderilen verileri arduino nun serial monitöründe gösteriyoruz.
    Serial.println("Veri gonderildi."); // Serial monitörde veri gönderildiğini dair bilgi veriyoruz.
    delay(3000);
  } 
  Serial.println("Baglantı Kapatildi.");
  esp.println("AT+CIPCLOSE");                                //Bağlantıyı kapatıyoruz
  delay(2000); 

}
void otomatikbesleme()
{
//Step motor kodları
  digitalWrite(dirPin, HIGH); // Saat yönünde döndüren kod

  // Step motorun adım sayısını belirleyen kısım
  for (int i = 0; i <steptur; i++) {
    digitalWrite(stepPin, HIGH);
    delayMicroseconds(800);
    digitalWrite(stepPin, LOW);
    delayMicroseconds(800);
  }

  delay(2000);

  digitalWrite(dirPin, LOW); // Saat yönünün tersine döndüren kod

  // Step motorun adım sayısını belirleyen kısım
  for (int i = 0; i <steptur; i++) {
    digitalWrite(stepPin, HIGH);
    delayMicroseconds(800);
    digitalWrite(stepPin, LOW);
    delayMicroseconds(800);
  }
   delay(3000);
}

void manuelbesleme(){


  
   digitalWrite(dirPin, HIGH); // Saat yönünde döndüren kod

  // Step motorun adım sayısını belirleyen kısım
  for (int i = 0; i <steptur; i++) {
    digitalWrite(stepPin, HIGH);
    delayMicroseconds(800);
    digitalWrite(stepPin, LOW);
    delayMicroseconds(800);
  }

  delay(800);

  digitalWrite(dirPin, LOW); // Saat yönünün tersine döndüren kod

  // Step motorun adım sayısını belirleyen kısım
  for (int i = 0; i <steptur; i++) {
    digitalWrite(stepPin, HIGH);
    delayMicroseconds(800);
    digitalWrite(stepPin, LOW);
    delayMicroseconds(800);
  }
  
 delay(12000);
}


String getJSON() { //getjson ile http get isteğini kullanarak thingspeak apıden json formatında veri alıyoruz
  String response = "";

  // HTTP GET isteği oluştur
  String request = "GET /channels/2170553/fields/3.json?api_key=Your API KEY&results=1 HTTP/1.1\r\n";// Thingspeakten veri alacağımız adres
  request += "Host: api.thingspeak.com\r\n";
  request += "Connection: close\r\n\r\n";

  esp.println("AT+CIPSEND=" + String(request.length())); //esp8266 ile http isteği göndererek thingspeak apiye veri gönderip yanıt alma
  if (esp.find(">")) {
    esp.print(request);

    // İsteğe ait yanıtı al
    unsigned long timeout = millis();
    while (millis() - timeout < 5000) {
      while (esp.available()) {
        char c = esp.read();
        response += c;
      }
    }
  }

  // JSON verilerini çıkar. response değişkenininde bulunan yanıttan json verilerini çıkarma
  int start = response.indexOf("{");
  int end = response.lastIndexOf("}");

  if (start >= 0 && end >= 0) { 
    response = response.substring(start, end + 1);
  }

  return response;
}

void wifi() {
  esp.begin(9600);

  esp.println("AT"); //ESP8266 modülünün kullanıma hazır olup olmadığını test eder.
  while (!esp.find("OK")) {
    esp.println("AT");
    Serial.println("ESP8266 Bulunamadı.");
  }

  esp.println("AT+CWMODE=1");
  while (!esp.find("OK")) {
    esp.println("AT+CWMODE=1");
    Serial.println("Ayar Yapılıyor....");
  }

  esp.println("AT+CWJAP=\"" + agAdi + "\",\"" + agSifresi + "\""); //Modülün kablosuz ağa bağlanmasını sağlar.
  while (!esp.find("OK")) ;

  Serial.println("Ağa Bağlandı.");
  delay(1000);
}
