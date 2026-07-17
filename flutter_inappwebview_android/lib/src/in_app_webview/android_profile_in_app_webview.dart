import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';

import '../find_interaction/find_interaction_controller.dart';
import '../pull_to_refresh/main.dart';
import '../pull_to_refresh/pull_to_refresh_controller.dart';
import 'headless_in_app_webview.dart';
import 'in_app_webview_controller.dart';

/// Android WebView widget that binds a non-default Android WebView Profile
/// before the native WebView is prepared or performs its initial navigation.
///
/// Pass a stable internal profile identifier. A null or blank value keeps the
/// Android System WebView default Profile and does not call
/// `WebViewCompat.setProfile`.
///
/// Profile binding cannot be combined with a running headless WebView or a
/// keep-alive WebView because those instances may already have performed work
/// under another Profile.
class AndroidProfileInAppWebViewWidget extends PlatformInAppWebViewWidget {
  AndroidProfileInAppWebViewWidget({
    required PlatformInAppWebViewWidgetCreationParams params,
    required this.profileName,
  }) : super.implementation(params);

  final String? profileName;

  AndroidInAppWebViewController? _controller;

  AndroidHeadlessInAppWebView? get _androidHeadlessInAppWebView =>
      params.headlessWebView as AndroidHeadlessInAppWebView?;

  AndroidPullToRefreshController? get _pullToRefreshController =>
      params.pullToRefreshController as AndroidPullToRefreshController?;

  AndroidFindInteractionController? get _findInteractionController =>
      params.findInteractionController as AndroidFindInteractionController?;

  @override
  Widget build(BuildContext context) {
    final normalizedProfileName = _normalizeProfileName(profileName);
    final headlessWebViewIsRunning =
        params.headlessWebView?.isRunning() ?? false;

    if (normalizedProfileName != null &&
        (headlessWebViewIsRunning || params.keepAlive != null)) {
      throw StateError(
        'Android WebView Profile binding cannot reuse a headless or keep-alive WebView.',
      );
    }

    final initialSettings = params.initialSettings ?? InAppWebViewSettings();
    _inferInitialSettings(initialSettings);

    final settingsMap =
        (params.initialSettings != null ? initialSettings.toMap() : null) ??
            // ignore: deprecated_member_use_from_same_package
            params.initialOptions?.toMap() ??
            initialSettings.toMap();

    final pullToRefreshSettings =
        params.pullToRefreshController?.params.settings.toMap() ??
            // ignore: deprecated_member_use_from_same_package
            params.pullToRefreshController?.params.options.toMap() ??
            PullToRefreshSettings(enabled: false).toMap();

    if (headlessWebViewIsRunning && params.keepAlive != null) {
      final headlessId = params.headlessWebView?.id;
      if (headlessId != null) {
        params.keepAlive?.id = headlessId;
      }
    }

    final useHybridComposition = (params.initialSettings != null
            ? initialSettings.useHybridComposition
            : params.initialOptions?.android.useHybridComposition) ??
        true;

    return PlatformViewLink(
      key: params.key,
      viewType: 'com.pichillilorenzo/flutter_inappwebview',
      surfaceFactory: (
        BuildContext context,
        PlatformViewController controller,
      ) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: params.gestureRecognizers ??
              const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (PlatformViewCreationParams creationParams) {
        return _createAndroidViewController(
          hybridComposition: useHybridComposition,
          id: creationParams.id,
          viewType: 'com.pichillilorenzo/flutter_inappwebview',
          layoutDirection: params.layoutDirection ??
              Directionality.maybeOf(context) ??
              TextDirection.rtl,
          creationParams: <String, dynamic>{
            'initialUrlRequest': params.initialUrlRequest?.toMap(),
            'initialFile': params.initialFile,
            'initialData': params.initialData?.toMap(),
            'initialSettings': settingsMap,
            'contextMenu': params.contextMenu?.toMap() ?? {},
            'windowId': params.windowId,
            'profileName': normalizedProfileName,
            'headlessWebViewId':
                headlessWebViewIsRunning ? params.headlessWebView?.id : null,
            'initialUserScripts': params.initialUserScripts
                    ?.map((script) => script.toMap())
                    .toList() ??
                [],
            'pullToRefreshSettings': pullToRefreshSettings,
            'keepAliveId': params.keepAlive?.id,
          },
        )
          ..addOnPlatformViewCreatedListener(
            creationParams.onPlatformViewCreated,
          )
          ..addOnPlatformViewCreatedListener(_onPlatformViewCreated)
          ..create();
      },
    );
  }

  AndroidViewController _createAndroidViewController({
    required bool hybridComposition,
    required int id,
    required String viewType,
    required TextDirection layoutDirection,
    required Map<String, dynamic> creationParams,
  }) {
    if (hybridComposition) {
      return PlatformViewsService.initExpensiveAndroidView(
        id: id,
        viewType: viewType,
        layoutDirection: layoutDirection,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return PlatformViewsService.initSurfaceAndroidView(
      id: id,
      viewType: viewType,
      layoutDirection: layoutDirection,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }

  void _onPlatformViewCreated(int id) {
    dynamic viewId = id;
    if (params.headlessWebView?.isRunning() ?? false) {
      viewId = params.headlessWebView?.id;
    }
    viewId = params.keepAlive?.id ?? viewId ?? id;
    _androidHeadlessInAppWebView?.internalDispose();
    _controller = AndroidInAppWebViewController(
      PlatformInAppWebViewControllerCreationParams(
        id: viewId,
        webviewParams: params,
      ),
    );
    _pullToRefreshController?.init(viewId);
    _findInteractionController?.init(viewId);
    debugLog(
      className: runtimeType.toString(),
      id: viewId?.toString(),
      debugLoggingSettings: PlatformInAppWebViewController.debugLoggingSettings,
      method: 'onWebViewCreated',
      args: const [],
    );
    if (params.onWebViewCreated != null) {
      params.onWebViewCreated!(
        params.controllerFromPlatform?.call(_controller!) ?? _controller!,
      );
    }
  }

  void _inferInitialSettings(InAppWebViewSettings settings) {
    if (params.shouldOverrideUrlLoading != null &&
        settings.useShouldOverrideUrlLoading == null) {
      settings.useShouldOverrideUrlLoading = true;
    }
    if (params.onLoadResource != null && settings.useOnLoadResource == null) {
      settings.useOnLoadResource = true;
    }
    if (params.onDownloadStartRequest != null &&
        settings.useOnDownloadStart == null) {
      settings.useOnDownloadStart = true;
    }
    if ((params.shouldInterceptAjaxRequest != null ||
            params.onAjaxProgress != null ||
            params.onAjaxReadyStateChange != null) &&
        settings.useShouldInterceptAjaxRequest == null) {
      settings.useShouldInterceptAjaxRequest = true;
    }
    if (params.shouldInterceptFetchRequest != null &&
        settings.useShouldInterceptFetchRequest == null) {
      settings.useShouldInterceptFetchRequest = true;
    }
    if (params.shouldInterceptRequest != null &&
        settings.useShouldInterceptRequest == null) {
      settings.useShouldInterceptRequest = true;
    }
    if (params.onRenderProcessGone != null &&
        settings.useOnRenderProcessGone == null) {
      settings.useOnRenderProcessGone = true;
    }
    if (params.onNavigationResponse != null &&
        settings.useOnNavigationResponse == null) {
      settings.useOnNavigationResponse = true;
    }
  }

  String? _normalizeProfileName(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  @override
  void dispose() {
    final viewId = _controller?.getViewId();
    debugLog(
      className: runtimeType.toString(),
      id: viewId?.toString(),
      debugLoggingSettings: PlatformInAppWebViewController.debugLoggingSettings,
      method: 'dispose',
      args: const [],
    );
    final isKeepAlive = params.keepAlive != null;
    _controller?.dispose(isKeepAlive: isKeepAlive);
    _controller = null;
    params.pullToRefreshController?.dispose(isKeepAlive: isKeepAlive);
    params.findInteractionController?.dispose(isKeepAlive: isKeepAlive);
  }

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) {
    throw UnimplementedError();
  }
}
