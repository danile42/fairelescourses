import 'dart:io';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:fairelescourses/hive_registrar.g.dart';
import 'package:fairelescourses/models/shopping_list.dart';
import 'package:fairelescourses/models/supermarket.dart';

/// Opens all Hive boxes needed by providers in a temp directory.
/// Call in setUpAll; call [tearDownHive] in tearDownAll.
Future<Directory> setUpHive() async {
  final dir = await Directory.systemTemp.createTemp('hive_test_');
  Hive.init(dir.path);
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapters();
  await Hive.openBox<ShoppingList>('shopping_lists');
  await Hive.openBox<Supermarket>('supermarkets');
  await Hive.openBox<String>('settings');
  return dir;
}

Future<void> tearDownHive(Directory dir) async {
  await Hive.close();
  await dir.delete(recursive: true);
}

/// Clears all open boxes between tests.
Future<void> clearHive() async {
  await Hive.box<ShoppingList>('shopping_lists').clear();
  await Hive.box<Supermarket>('supermarkets').clear();
  await Hive.box<String>('settings').clear();
}
