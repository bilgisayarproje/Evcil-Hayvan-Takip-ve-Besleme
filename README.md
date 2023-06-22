# mamamatik_proje

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Evcil Hayvan Takip ve Besleme 
1->Arduino Kodları 

1.1->Kamera Arduino
İlk olarak Arduinoda File-->Preferences-->Settings kısmında Additional boards manager Url kısmına https://arduino.esp8266.com/stable/package_esp8266com_index.json yazıp tamam basıyorsunuz. Daha sonra kard yükleme kısmında için esp32 ve esp8266 kartlarını yüklüyorsunuz. Esp32cam Wovewer Module ü seçip karta yükleme yapıyorsunuz.Ağa bağlandıktan sonra serial monitörde kameranın İp adresini gösterecek. Bu ip adresini internet tarayıcısına girerseniz görüntü almış olacaksınız.

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

SSID yazan kısma kablosuz ağ adını ve password yazana kısma şifreyi giriyorsunuz. 

1.2-> Mamamatik Arduino

Kütüphane yükleme alanından Thingspeak, ArduinoJson ve HX711 kütüphanelerini yüklüyoruz. Burada kodları çalıştırmak için Arduino mega kartını seçiyoruz. agAdi ve agSifresi yazan yer kablosuz ağ bilgilerini giriyoruz.  gonderilenveri değişkenine Thingspeak teki read channel API key adresini giriyoruz.  request değişkenine de Thingspeak teki Write channel API key adresini giriyoruz. Ağırlık, mesafe, Esp8266 pinlerini kodda belirtilen sayılara bağlıyoruz. Programı karta yüklüyoruz. Sensörlerden alınan verileri arduinodan thingspeak a göndermeyi sağlıyoruz.

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

2->Android Kodları 

Android studioda bir proje oluşturuyoruz. Firebase ile bağlantılarını sağlamak için Firebase CLI işlemlerini yapıyoruz. Burada Clı işlemlerine https://firebase.google.com/docs/cli?hl=tr ulaşabilirsiniz. Bu işlemleri yapınca projeye firebaseoption.dart ve googlejson.services dosyaları ekliyor ve firebase bağlanmak için gerekli işlemleri yapıyor. 

Firebase'de bir hesap açıyoruz. Bu hesabın içerisinde authentication bölümü seçiyoruz. Email provider kısmını aktif ediyoruz. 

2.1-> Main.dart Kodları

import 'package:flutter/material.dart'; //flutter kütüphanesini ekleme
import 'package:firebase_core/firebase_core.dart'; //firebase kütüphanesini ekleme
import 'auth_gate.dart'; //giriş ekranı dosyasını içeri aktarma
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); //flutterın başlatılması
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions
          .currentPlatform); //firebase kullanıma hazır hale getiriliyor
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @OverRide
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mamamatik',
      home: AuthGate(),
    );
  }
}

2.2-> auth_gate.dart Kodları
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:mamamatik_proje/anasayfa.dart';
import 'package:firebase_database/firebase_database.dart';

FirebaseDatabase database = FirebaseDatabase.instance;

DatabaseReference ref = FirebaseDatabase.instance.ref("users/123");

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  static const String _title = 'Mamamatik';

  @OverRide
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          //anlık görüntü
          if (!snapshot.hasData) {
            return const SignInScreen(
              providerConfigs: [EmailProviderConfiguration()],
            );
          }
          return Scaffold(
            body: Mamamatik(),
          );
        });
  }
}
2.3-> anasayfa.dart Kodları

import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedData {
  //feed data sınıfını tanımlıyoruz
  final double field1;
  final double field2;
  final DateTime timestamp;

  FeedData({
    //feed data sınıfının yapıcı metodunu tanımlıyoruz başlangıç değerlerinin ataması gerçekleştiriliyor
    required this.field1,
    required this.field2,
    required this.timestamp,
  });
}

class Mamamatik extends StatefulWidget {
  @OverRide
  _MamamatikState createState() => _MamamatikState();
}

class _MamamatikState extends State<Mamamatik> {
  double progressValue1 = 0.0; //birinci ilerleme çubuğunun değerini tutar
  double progressValue2 = 0.0; //ikinci ilerleme çubuğunun değerini tutar
  List<FeedData> feedDataList = []; //veri akışı verilerini depolar

  Future<void> fetchData() async {
    // URL'ye GET isteği göndererek Thingspeak'ten veri alma işlemi
    final response = await http.get(Uri.parse(
        'https://api.thingspeak.com/channels/2170553/feeds.json?api_key=3ZVDDT72FXPN6VC4&results=1'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response
          .body); //response body içeriğini json formatında data değişkenine atama
      final feeds = data[
          'feeds']; //data içerisindeki "feeds" alanını feeds değişkenine atama

      List<FeedData> tempList =
          []; //geçici olarak yeni FeedData nesneleri depolamak için boş liste tanımlama

      for (var feed in feeds) {
        double field1Value = double.parse(
            feed['field1']); //feed öğesindeki field1 alanının değerini atar
        double field2Value = double.parse(
            feed['field2']); //feed öğesindeki field2 alanının değerini atar
        DateTime timestampValue = DateTime.parse(feed[
            'created_at']); // feed öğesindeki created at alanının değerini atar

        FeedData feedData = FeedData(
          //her bir feed için feed data nesnesi oluşturulur
          field1: field1Value, //field1value değeri field1 e atanır
          field2: field2Value, //field2value değeri field2 ye atanır
          timestamp: timestampValue, //timestampvalue değeri timestamp e atanır
        );

        tempList.add(feedData); //feeddata nesnesi templiste eklenir
      }

      setState(() {
        //durum değişikliği yapma ve feeddatalist listeni güncelleme
        feedDataList = tempList;
        if (feedDataList.isNotEmpty) {
          progressValue1 = feedDataList[0]
              .field1; //feedDataList listesindeki ilk öğenin field1 değerini progressValue1 e atar
          progressValue2 = feedDataList[0]
              .field2; //feedDataList listesindeki ilk öğenin field2 değerini progressValue2 e atar
        }
      });
    } else {
      throw Exception('Failed to fetch data from ThingSpeak'); //hata durumu
    }
  }

  @OverRide
  void initState() {
    super.initState();
    fetchData();
    Timer.periodic(Duration(seconds: 1), (Timer timer) {
      fetchData(); //1 saniye aralıklarla fetchData() fonksiyonu çağrılır ve yeni veriler alınır
    });
  }

  void _logout() {
    //kullanıcı oturumu sonlandırma
    FirebaseAuth.instance.signOut();
  }

  Future<void> _launchURL() async {
    //esp 32 cam e ait url yi açma
    const url = 'http://192.168.43.211:81/stream';
    if (await canLaunch(url)) {
      // url açma yeteneğinin kontrol edilmesi
      await launch(url); //
    } else {
      throw 'Could not launch URL: $url'; // url açılamıyorsa hata durumu
    }
  }

  void _manuelBeslemeAc() async {
    //thingspeak apisini kullanarak field3 1 olarak güncelleme
    final response = await http.get(Uri.parse(
        'https://api.thingspeak.com/update?api_key=SIITATBBK2J6GDBP&field3=1'));
    if (response.statusCode == 200) {
      showDialog(
        //iletişim kutusunu görüntüleme
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Manuel Besleme'),
            content: Text('Manuel Besleme Yapıldı'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // iletişim kutusunu kapama
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      Timer(Duration(seconds: 20), () {
        _manuelBeslemeKapat();
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Manuel Besleme'),
            content: Text('Manuel Besleme Yapılamadı'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _manuelBeslemeKapat() async {
    final response = await http.get(Uri.parse(
        'https://api.thingspeak.com/update?api_key=SIITATBBK2J6GDBP&field3=0')); //field 3 0 olarak güncellenir
    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Manuel Besleme'),
            content: Text('Manuel Besleme Kapatıldı'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Manuel Besleme'),
            content: Text('Manuel Besleme Kapatılamadı'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @OverRide
  Widget build(BuildContext context) {
    //arayüzün oluşturulup düzenlendiği alan
    return Scaffold(
      appBar: AppBar(
        //uygulama başlığı ve çıkış düğmesinin bulunduğu alan
        title: Text('MAMAMATİK UYGULAMASI'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        //center widgetı içeriği ortalama işlemi yapar
        child: _selectedIndex == 0
            ? Column(
                //kullanılacak widgetlar dikey olarak ortalanır
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Mama Kabı Mesafesi',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
                  ),
                  CircularPercentIndicator(
                    //yuvarlak ilerleme çubuğunun yarıçap, çubuk kalınlığı ve doluluk oranlarına ait ayarlar
                    radius: 110.0,
                    lineWidth: 20.0,
                    percent: 1 - progressValue1 / 22,
                    center: Text(
                      '${progressValue1.toStringAsFixed(0)} cm',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20.0),
                    ),
                    progressColor: Colors.blue,
                  ),
                  SizedBox(height: 20.0),
                  Text(
                    'Kabın Ağırlığı',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
                  ),
                  CircularPercentIndicator(
                    radius: 110.0,
                    lineWidth: 20.0,
                    percent: progressValue2 / 600,
                    center: Text(
                      '${progressValue2.toStringAsFixed(0)} gram',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20.0),
                    ),
                    progressColor: Colors.green,
                  ),
                ],
              )
            : ListView.builder(
                // feeddatalist içindeki veri ögeleri için tarih saat bilgisi ile liste oluşturur
                itemCount: feedDataList.length,
                itemBuilder: (context, index) {
                  FeedData feedData = feedDataList[index];
                  String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss')
                      .format(feedData.timestamp);

                  return ListTile(
                    //liste ekrana yazdırılıyor
                    title: Text('Data ${index + 1}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kontrol Tarihi: $formattedDate'),
                        Text(
                            'Kabı Mesafesi: ${feedData.field1.toStringAsFixed(0)} cm'),
                        Text(
                            'Kabın Ağırlığı: ${feedData.field2.toStringAsFixed(0)} gram'),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _launchURL,
            child: Icon(Icons.camera_alt),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            mini: true,
            heroTag: null,
            tooltip: 'Kamerayı Aç',
          ),
          SizedBox(height: 16.0),
          FloatingActionButton(
            onPressed: _manuelBeslemeAc,
            child: Icon(Icons.add),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            mini: true,
            heroTag: null,
            tooltip: 'Manuel Besleme',
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Anasayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Liste',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
      ),
    );
  }

  int _selectedIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

Uygulama kullanıcı ve şifre işlemleri ile başlıyor. Sign in kısmında bir mail adresi ile kayıt işlemlerini yapabiliyoruz. Kaydedilen maillere authentication bölümünde görebiliyoruz. 
Belirlediğimiz kullanıcı ve şifre ile uygulamanın anasayfasına giriş yapabiliyoruz. Thingspeak e arduinodan çektirdiğimiz ağırlık ve mesafe verilerinin listelerini ve değerlerini görebiliyoruz. Ayrıca uygulama içerisinde manuel besleme butonu ile thingspeak e veri göndererek oradan da arduino da değeri çektirerek step motoru çalıştırmış oluyoruz. Ayrıca kamera butonuna tıklayarak sitemi canlı olarak izleyebiliyoruz.
