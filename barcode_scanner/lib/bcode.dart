import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barcode_scan2/barcode_scan2.dart'; // Import barcode scan package
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers package

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});
  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScannerPage> {
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final CollectionReference myItems =
      FirebaseFirestore.instance.collection("crud");

  final AudioPlayer audioPlayer = AudioPlayer(); // Initialize audio player

  // Function to start barcode scanning
  Future<void> startBarcodeScan() async {
    try {
      var result = await BarcodeScanner.scan(); // Start the scanner
      setState(() {
        barcodeController.text =
            result.rawContent; // Set scanned result into the barcode field
      });

      // Play sound on successful scan
      if (result.rawContent.isNotEmpty) {
        await playSound();
      }
    } catch (e) {
      setState(() {
        barcodeController.text = "Failed to scan barcode: $e";
      });
    }
  }

  // Function to play sound
  Future<void> playSound() async {
    await audioPlayer
        .play(AssetSource('audio/barcode.mp3')); // Play the beep sound
  }

  Future<void> create() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return myDialogBox(
          context: context,
          name: 'Бараа',
          position: 'Нэмэх',
          barcodeController: barcodeController,
          nameController: nameController,
          priceController: priceController,
          descController: descController,
          onPressed: () {
            String barcode = barcodeController.text;
            String name = nameController.text;
            String price = priceController.text;
            String desc = descController.text;
            addItems(barcode, name, price, desc);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void addItems(String barcode, String name, String price, String desc) {
    myItems.add({
      'name': name,
      'barcode': barcode,
      'price': price,
      'desc': desc,
    });
  }

  Future<void> update(DocumentSnapshot documentSnapshot) async {
    barcodeController.text = documentSnapshot['barcode'];
    nameController.text = documentSnapshot['name'];
    priceController.text = documentSnapshot['price'];
    descController.text = documentSnapshot['desc'];
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return myDialogBox(
          context: context,
          name: 'Засах хэсэг',
          position: 'Засах',
          barcodeController: barcodeController,
          nameController: nameController,
          priceController: priceController,
          descController: descController,
          onPressed: () async {
            String barcode = barcodeController.text;
            String name = nameController.text;
            String price = priceController.text;
            String desc = descController.text;
            await myItems.doc(documentSnapshot.id).update({
              'name': name,
              'barcode': barcode,
              'price': price,
              'desc': desc,
            });
            barcodeController.text = '';
            nameController.text = '';
            priceController.text = '';
            descController.text = '';
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> delete(String productId) async {
    await myItems.doc(productId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        duration: Duration(milliseconds: 1500),
        content: Text("Амжилттай устгагдлаа"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Бараа нэмэх хэсэг')),
      body: StreamBuilder<QuerySnapshot>(
        stream: myItems.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No items found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final documentSnapshot = snapshot.data!.docs[index];

              // Safely access fields with try-catch
              final name = documentSnapshot.get('name') ?? 'Unnamed';
              final barcode =
                  documentSnapshot.get('barcode')?.toString() ?? 'N/A';
              final price = documentSnapshot.get('price')?.toString() ?? 'N/A';

              // Safely handling missing 'desc' field
              String desc = 'No description';
              try {
                desc = documentSnapshot.get('desc') ?? 'No description';
              } catch (e) {
                // Field 'desc' does not exist, use default value
              }

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Material(
                  elevation: 5,
                  borderRadius: BorderRadius.circular(20),
                  child: ListTile(
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    subtitle: Text(
                      'Баркод: $barcode\n'
                      'Үнэ: $price\n'
                      'Тайлбар: $desc',
                    ),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => update(documentSnapshot),
                            icon: const Icon(
                              Icons.edit,
                            ),
                          ),
                          IconButton(
                            onPressed: () => delete(documentSnapshot.id),
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await startBarcodeScan(); // Start scanning when button pressed
          await create(); // Open the dialog after scanning
        },
        backgroundColor: Colors.blue,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}

Dialog myDialogBox({
  required BuildContext context,
  required String name,
  required String position,
  required TextEditingController barcodeController,
  required TextEditingController nameController,
  required TextEditingController priceController,
  required TextEditingController descController,
  required VoidCallback onPressed,
}) =>
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(); // Use the passed context to close dialog
                  },
                  icon: const Icon(Icons.close),
                )
              ],
            ),
            TextField(
              controller: barcodeController,
              decoration: const InputDecoration(
                labelText: 'Баркод',
              ),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Бүтээгдэхүүний нэр',
              ),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Үнэ',
              ),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Тайлбар',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onPressed,
              child: Text(position),
            ),
          ],
        ),
      ),
    );
