import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview_android/flutter_inappwebview_android.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';

import 'in_app_webview.dart';
import 'in_app_webview_controller.dart';

/// High-level Android WebView that binds a non-default Android WebView Profile
/// before native WebView initialization and the first navigation.
///
/// Use a stable internal identifier for [profileName]. The default Profile must
/// continue to use the standard [InAppWebView] widget.
class AndroidProfileInAppWebView extends InAppWebView {
  AndroidProfileInAppWebView({
    required String profileName,
    Key? key,
    int? windowId,
    InAppWebViewInitialData? initialData,
    InAppWebViewSettings? initialSettings,
    URLRequest? initialUrlRequest,
    void Function(InAppWebViewController controller)? onWebViewCreated,
    void Function(InAppWebViewController controller, int progress)?
        onProgressChanged,
    void Function(InAppWebViewController controller, WebUri? url)? onLoadStop,
    void Function(InAppWebViewController controller, String? title)?
        onTitleChanged,
    Future<bool?> Function(
      InAppWebViewController controller,
      CreateWindowAction createWindowAction,
    )? onCreateWindow,
    void Function(InAppWebViewController controller)? onCloseWindow,
    void Function(
      InAppWebViewController controller,
      DownloadStartRequest downloadStartRequest,
    )? onDownloadStartRequest,
    void Function(
      InAppWebViewController controller,
      WebResourceRequest request,
      WebResourceError error,
    )? onReceivedError,
    Future<NavigationActionPolicy?> Function(
      InAppWebViewController controller,
      NavigationAction navigationAction,
    )? shouldOverrideUrlLoading,
  }) : super.fromPlatform(
          key: key,
          platform: AndroidProfileInAppWebViewWidget(
            profileName: profileName,
            params: PlatformInAppWebViewWidgetCreationParams(
              controllerFromPlatform: (controller) =>
                  InAppWebViewController.fromPlatform(platform: controller),
              windowId: windowId,
              initialData: initialData,
              initialSettings: initialSettings,
              initialUrlRequest: initialUrlRequest,
              onWebViewCreated: onWebViewCreated == null
                  ? null
                  : (controller) => onWebViewCreated(
                        controller as InAppWebViewController,
                      ),
              onProgressChanged: onProgressChanged == null
                  ? null
                  : (controller, progress) => onProgressChanged(
                        controller as InAppWebViewController,
                        progress,
                      ),
              onLoadStop: onLoadStop == null
                  ? null
                  : (controller, url) => onLoadStop(
                        controller as InAppWebViewController,
                        url,
                      ),
              onTitleChanged: onTitleChanged == null
                  ? null
                  : (controller, title) => onTitleChanged(
                        controller as InAppWebViewController,
                        title,
                      ),
              onCreateWindow: onCreateWindow == null
                  ? null
                  : (controller, action) => onCreateWindow(
                        controller as InAppWebViewController,
                        action,
                      ),
              onCloseWindow: onCloseWindow == null
                  ? null
                  : (controller) => onCloseWindow(
                        controller as InAppWebViewController,
                      ),
              onDownloadStartRequest: onDownloadStartRequest == null
                  ? null
                  : (controller, request) => onDownloadStartRequest(
                        controller as InAppWebViewController,
                        request,
                      ),
              onReceivedError: onReceivedError == null
                  ? null
                  : (controller, request, error) => onReceivedError(
                        controller as InAppWebViewController,
                        request,
                        error,
                      ),
              shouldOverrideUrlLoading: shouldOverrideUrlLoading == null
                  ? null
                  : (controller, action) => shouldOverrideUrlLoading(
                        controller as InAppWebViewController,
                        action,
                      ),
            ),
          ),
        );
}
