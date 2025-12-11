import 'package:flutter/material.dart';

class MenuController extends ChangeNotifier {
  int selectedIndex = 0;

  void selectMenu(int index) {
    selectedIndex = index;
    notifyListeners();
  }
}
