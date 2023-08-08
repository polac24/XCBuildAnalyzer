//
//  BuildAnalyzerApp.swift
//  BuildAnalyzer
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import SwiftUI
import BuildAnalyzerKit

@main
struct BuildAnalyzerApp: App {
    var body: some Scene {
        WindowGroup {
            let url = URL(fileURLWithPath:  "/Users/bartosz/Development/BuildG/DerivedData/BuildG/Build/Intermediates.noindex/XCBuildData/7f298f85ff0a7d4faa437918d6a25d9f.xcbuilddata/manifest.json")
            let graph = try! buildGraph(url: url)
            let webView = GraphWebView(graph: graph)
            ContentView(
                graph: graph, filteredItems: [], web:webView
            )
        }
    }
}
