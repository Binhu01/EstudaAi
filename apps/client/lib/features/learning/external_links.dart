import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

bool isStudyLink(Uri uri) =>
    uri.scheme == 'https' &&
    uri.userInfo.isEmpty &&
    !uri.hasPort &&
    const {
      'www.youtube.com',
      'youtube.com',
      'pt.khanacademy.org',
      'ceale.fae.ufmg.br',
    }.contains(uri.host);
Future<bool> openStudyLink(Uri url) async {
  if (!isStudyLink(url)) return false;
  try {
    return await launchUrl(
      url,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
  } catch (_) {
    return false;
  }
}

final externalLinkProvider = Provider<Future<bool> Function(Uri)>(
  (ref) => openStudyLink,
);
