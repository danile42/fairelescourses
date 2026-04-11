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
  await Hive.openBox<String>('item_categories');
  await Hive.openBox<String>('deleted_list_ids');
  return dir;
}

Future<void> tearDownHive(Directory dir) async {
  // Hive.close() can hang indefinitely when a test wrote to a Hive box inside
  // a testWidgets block (FakeAsync zone) and the write never flushed — e.g.
  // when tapping "Start navigation" writes 'singleNavActive'. Cap the wait at
  // 5 s; since we delete the temp dir immediately after, any unflushed data is
  // safely discarded.
  try {
    await Hive.close().timeout(const Duration(seconds: 5));
  } catch (_) {}
  await dir.delete(recursive: true);
}

/// Clears all open boxes between tests.
Future<void> clearHive() async {
  await Hive.box<ShoppingList>('shopping_lists').clear();
  await Hive.box<Supermarket>('supermarkets').clear();
  await Hive.box<String>('settings').clear();
  await Hive.box<String>('item_categories').clear();
  await Hive.box<String>('deleted_list_ids').clear();
}
