import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class HomeLocation {
  final String address;
  final double lat;
  final double lng;

  const HomeLocation({
    required this.address,
    required this.lat,
    required this.lng,
  });
}

class HomeLocationNotifier extends StateNotifier<HomeLocation?> {
  HomeLocationNotifier() : super(_load());

  static HomeLocation? _load() {
    final box = Hive.box<String>('settings');
    final addr = box.get('homeAddress');
    final lat = double.tryParse(box.get('homeLat') ?? '');
    final lng = double.tryParse(box.get('homeLng') ?? '');
    if (addr == null || lat == null || lng == null) return null;
    return HomeLocation(address: addr, lat: lat, lng: lng);
  }

  Future<void> set(String address, double lat, double lng) async {
    final box = Hive.box<String>('settings');
    await box.put('homeAddress', address);
    await box.put('homeLat', lat.toString());
    await box.put('homeLng', lng.toString());
    state = HomeLocation(address: address, lat: lat, lng: lng);
  }

  Future<void> clear() async {
    final box = Hive.box<String>('settings');
    await box.delete('homeAddress');
    await box.delete('homeLat');
    await box.delete('homeLng');
    state = null;
  }
}

final homeLocationProvider =
    StateNotifierProvider<HomeLocationNotifier, HomeLocation?>(
  (ref) => HomeLocationNotifier(),
);
