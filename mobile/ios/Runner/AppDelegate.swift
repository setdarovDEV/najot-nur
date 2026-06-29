import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var securityChannel: FlutterMethodChannel?
  private var captureObserver: NSObjectProtocol?
  private var mirrorObserver: NSObjectProtocol?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // FCM / push notifications: register for remote notifications so iOS will
    // deliver device pushes when the user grants permission.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    application.registerForRemoteNotifications()

    // iOS does not expose a public API to block screen recording the way
    // Android's FLAG_SECURE does. The best we can do is:
    //   1) detect when the user starts recording the screen
    //      (UIScreen.capturedDidChangeNotification), and
    //   2) detect when the device is mirroring to an external display
    //      (UIScreen.didConnectNotification / UIScreen.didDisconnectNotification).
    // The Dart layer reacts to those notifications by either showing a
    // black overlay or blurring sensitive content.
    setupScreenCaptureObserver()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "notiqai/security",
      binaryMessenger: engineBridge.binaryMessenger
    )
    securityChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "isCaptured":
        result(UIScreen.main.isCaptured)
      case "isMirrored":
        // iOS does not expose an explicit "mirroring" flag; the only reliable
        // proxy is "is there more than one screen attached" once the second
        // screen connects. We always read the live state here.
        result(UIScreen.screens.count > 1)
      case "isSecure":
        // iOS cannot actually prevent capture; we report `true` when the app
        // is in the foreground (the user would notice the warning overlay
        // anyway) and `false` when running in the background.
        result(UIApplication.shared.applicationState == .active)
      case "isRooted":
        // Best-effort jailbreak signal. iOS is far less exposed than Android,
        // so this is a placeholder that returns false unless we add
        // additional checks (e.g. sandbox write outside the container).
        result(false)
      case "getDeviceInfo":
        let device = UIDevice.current
        result([
          "platform": "ios",
          "os_version": device.systemVersion,
          "device_model": device.model,
          "device_name": device.name,
          "is_captured": UIScreen.main.isCaptured,
          "screen_count": UIScreen.screens.count,
        ])
      case "setSecure":
        // No-op on iOS. We acknowledge so the Dart side can be platform
        // agnostic. The capture observer installed in
        // setupScreenCaptureObserver() is what actually protects content.
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func setupScreenCaptureObserver() {
    let center = NotificationCenter.default
    captureObserver = center.addObserver(
      forName: UIScreen.capturedDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      let captured = UIScreen.main.isCaptured
      self?.securityChannel?.invokeMethod(
        "onScreenCapturedChanged",
        arguments: ["captured": captured]
      )
    }
    mirrorObserver = center.addObserver(
      forName: UIScreen.didConnectNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.securityChannel?.invokeMethod(
        "onScreenCapturedChanged",
        arguments: ["captured": UIScreen.screens.count > 1]
      )
    }
    let disconnectObserver = center.addObserver(
      forName: UIScreen.didDisconnectNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.securityChannel?.invokeMethod(
        "onScreenCapturedChanged",
        arguments: ["captured": UIScreen.main.isCaptured]
      )
    }
    // Keep the disconnect observer alive by stashing it on the AppDelegate.
    objc_setAssociatedObject(
      self, &AppDelegate.disconnectKey, disconnectObserver,
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )
  }

  private static var disconnectKey: UInt8 = 0
}
