import 'package:share_plus/share_plus.dart';

Future<void> shareText(String text) async {
  await SharePlus.instance.share(ShareParams(text: text));
}
