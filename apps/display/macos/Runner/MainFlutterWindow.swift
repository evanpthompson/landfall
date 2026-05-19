import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Native floor matches windowManager.setMinimumSize in main.dart.
    // Set here so the OS refuses sub-floor drags before Dart starts.
    self.contentMinSize = NSSize(width: 1280, height: 720)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
