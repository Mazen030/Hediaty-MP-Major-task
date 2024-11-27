import 'package:flutter/material.dart';

class GiftFilterSort {
  static List<Map<String, dynamic>> filterGifts(
      List<Map<String, dynamic>> gifts, String category, bool showPledged) {
    return gifts
        .where((gift) =>
    (category == 'All' || gift['category'] == category) &&
        (showPledged || !gift['pledged']))
        .toList();
  }

  static void sortGifts(List<Map<String, dynamic>> gifts, String sortBy) {
    if (sortBy == 'Name') {
      gifts.sort((a, b) => a['name'].compareTo(b['name']));
    } else if (sortBy == 'Category') {
      gifts.sort((a, b) => a['category'].compareTo(b['category']));
    }
  }
}
