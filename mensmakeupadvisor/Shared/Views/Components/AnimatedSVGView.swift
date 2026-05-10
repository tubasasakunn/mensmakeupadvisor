import SwiftUI
import WebKit

struct AnimatedSVGView: UIViewRepresentable {
    let svgName: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = Self.svgURL(named: svgName),
              let svgContent = try? String(contentsOf: url, encoding: .utf8) else {
            return
        }

        // SVG をコンテナにフィット（preserveAspectRatio のデフォルト xMidYMid meet で縦横比保持）
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <style>
          * { margin:0; padding:0; box-sizing:border-box; }
          html, body { width:100%; height:100%; background:transparent; overflow:hidden; }
          body { display:flex; align-items:center; justify-content:center; }
          svg { width:100%; height:100%; max-width:100%; max-height:100%; display:block; }
        </style>
        </head>
        <body>
        \(svgContent)
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: url.deletingLastPathComponent())
    }

    // バンドル内のSVGファイルを探す（ディレクトリ構造が保持されるか不定なので両方試す）
    static func svgURL(named name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "svg", subdirectory: "SVG")
            ?? Bundle.main.url(forResource: name, withExtension: "svg")
    }

    static func exists(named name: String) -> Bool {
        svgURL(named: name) != nil
    }
}
