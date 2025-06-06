import 'dart:html' as html;
import 'dart:ui_web' as ui_web; // !!!
import 'package:flutter/widgets.dart';

void registerMapIframe(String viewType, String url) {
  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) => html.IFrameElement()
      ..src = url
      ..style.border = '0'
      ..width = '100%'
      ..height = '300',
  );
}

Widget buildMapIframe(String viewType) => HtmlElementView(viewType: viewType);
