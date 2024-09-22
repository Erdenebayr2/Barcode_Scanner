import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final _fire = FirebaseFirestore.instance;

  create() {
    try {
      _fire.collection("products").add({
        "barcode": 8656000610187,
        "name": 'notebook',
        "price": 1000,
        "desc": "Sample product description"
      });
    } catch (e) {
      log(e.toString());
    }
  }
}
