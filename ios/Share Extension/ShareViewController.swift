import receive_sharing_intent

/// The Share Extension entry point. All the heavy lifting (reading the shared
/// items and redirecting into the host app) lives in the plugin's
/// `RSIShareViewController`; we only subclass it.
class ShareViewController: RSIShareViewController {
    // Return false here if you want the user to confirm inside the share sheet
    // before the app opens. Default (true) redirects immediately.
    // override func shouldAutoRedirect() -> Bool { return false }
}
