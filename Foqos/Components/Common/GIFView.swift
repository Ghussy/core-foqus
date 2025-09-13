import SwiftUI
import WebKit

struct GIFView: UIViewRepresentable {
  let gifName: String
  let subdirectory: String?

  func makeUIView(context: Context) -> WKWebView {
    let config = WKWebViewConfiguration()
    config.allowsAirPlayForMediaPlayback = false
    config.allowsInlineMediaPlayback = true
    let webView = WKWebView(frame: .zero, configuration: config)
    webView.isOpaque = false
    webView.backgroundColor = .clear
    webView.scrollView.isScrollEnabled = false
    webView.scrollView.backgroundColor = .clear
    webView.isUserInteractionEnabled = false
    // Perform an initial load so the GIF appears on first render
    loadGIF(into: webView)
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {
    // Reload asynchronously to avoid timing/layout issues on first appearance
    DispatchQueue.main.async {
      loadGIF(into: webView)
    }
  }

  private func loadGIF(into webView: WKWebView) {
    guard let data = loadGIFData() else { return }
    let html = """
    <html>
      <head>
        <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0'>
        <style>
          html, body { margin:0; padding:0; background: transparent; height:100%; }
          img { display:block; margin: auto; height: 100%; width: auto; object-fit: contain; }
        </style>
      </head>
      <body>
        <img src='data:image/gif;base64,\(data.base64EncodedString())' />
      </body>
    </html>
    """
    webView.loadHTMLString(html, baseURL: nil)
  }

  private func loadGIFData() -> Data? {
    let bundle = Bundle.main
    if let sub = subdirectory,
       let url = bundle.url(forResource: gifName, withExtension: "gif", subdirectory: sub),
       let data = try? Data(contentsOf: url) {
      return data
    }
    if let url = bundle.url(forResource: gifName, withExtension: "gif"),
       let data = try? Data(contentsOf: url) {
      return data
    }
    return nil
  }
}


