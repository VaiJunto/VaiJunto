// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

bool get isIosBrowser {
  final agent = html.window.navigator.userAgent.toLowerCase();
  return agent.contains('iphone') ||
      agent.contains('ipad') ||
      agent.contains('ipod');
}

bool get isRunningAsInstalledPwa {
  return html.window.matchMedia('(display-mode: standalone)').matches;
}
