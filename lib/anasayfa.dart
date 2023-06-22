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
    //feed data sınıfının yapıcı metodunu tanımlıyoruz
    required this.field1,
    required this.field2,
    required this.timestamp,
  });
}

class Mamamatik extends StatefulWidget {
  @override
  _MamamatikState createState() => _MamamatikState();
}

class _MamamatikState extends State<Mamamatik> {
  double progressValue1 = 0.0; //birinci ilerleme çubuğunun değerini tutar
  double progressValue2 = 0.0; //ikinci ilerleme çubuğunun değerini tutar
  List<FeedData> feedDataList = []; //veri akışı verilerini depolar

  Future<void> fetchData() async {
    // URL'ye GET isteği göndererek Thingspeak'ten veri alma işlemi
    final response = await http.get(Uri.parse(
        'https://api.thingspeak.com/channels/Your Channel/feeds.json?api_key=your API KEY&results=10'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response
          .body); //response body içeriğini json formatında data değişkenine atma
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

  @override
  void initState() {
    super.initState();
    fetchData();
    Timer.periodic(Duration(seconds: 300), (Timer timer) {
      fetchData(); //300 saniye aralıklarla fetchData() fonksiyonu çağrılır ve yeni veriler alınır
    });
  }

  void _logout() {
    FirebaseAuth.instance.signOut();
  }

  Future<void> _launchURL() async {
    const url = 'http://Your camera İP adress';
    if (await canLaunch(url)) {
      // url açma yeteneğinin kontrol edilmesi
      await launch(url); //
    } else {
      throw 'Could not launch URL: $url'; // url açılamıyorsa hata durumu
    }
  }

  void _manuelBeslemeAc() async {
    final response = await http.get(Uri.parse(
        'https://api.thingspeak.com/update?api_key=Your API KEY&field3=1'));
    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Manuel Besleme'),
            content: Text('Manuel Besleme Yapıldı'),
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
        'https://api.thingspeak.com/update?api_key=Your API >KEY&field3=0'));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MAMAMATİK UYGULAMASI'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: _selectedIndex == 0
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Mama Kabı Mesafesi',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
                  ),
                  CircularPercentIndicator(
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
                itemCount: feedDataList.length,
                itemBuilder: (context, index) {
                  FeedData feedData = feedDataList[index];
                  String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss')
                      .format(feedData.timestamp);

                  return ListTile(
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
