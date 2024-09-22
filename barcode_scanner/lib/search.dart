import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String scanResult = "_____";
  final AudioPlayer audioPlayer = AudioPlayer();
  final CollectionReference myItems =
      FirebaseFirestore.instance.collection("crud");
  String name = '';
  String price = '';
  String desc = '';

  Future<void> startBarcodeScan() async {
    try {
      var result = await BarcodeScanner.scan();
      setState(() {
        scanResult = result.rawContent;
      });

      if (result.rawContent.isNotEmpty) {
        await playSound();
        await searchByBarcode(result.rawContent);
      }
    } catch (e) {
      setState(() {
        scanResult = "Failed to scan barcode: $e";
      });
    }
  }

  Future<void> playSound() async {
    await audioPlayer.play(AssetSource('audio/barcode.mp3'));
  }

  Future<void> searchByBarcode(String barcode) async {
    try {
      QuerySnapshot querySnapshot =
          await myItems.where('barcode', isEqualTo: barcode).get();

      if (querySnapshot.docs.isNotEmpty) {
        var documentSnapshot = querySnapshot.docs.first;
        setState(() {
          name = documentSnapshot['name'];
          price = documentSnapshot['price'];
          desc = documentSnapshot['desc'];
        });
      } else {
        setState(() {
          name = '';
          price = '';
          desc = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No item found for the scanned barcode.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error searching item: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Бараа хайлтын хэсэг')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: startBarcodeScan,
              child: const Text('Бар кодыг уншуулна уу?'),
            ),
            const SizedBox(height: 20),
            Text('Баркод: $scanResult'),
            const SizedBox(height: 20),
            name.isNotEmpty
                ? Card(
                    margin: const EdgeInsets.all(16.0),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Нэр: $name',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text('Үнэ: $price',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text('Тайлбар: $desc',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                : const Text('Бүтээгдэхүүн илэрсэнгүй',
                    style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
