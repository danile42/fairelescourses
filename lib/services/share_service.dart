import 'package:share_plus/share_plus.dart';

Future<void> shareText(String text) async {
  await Share.share(text);
}
