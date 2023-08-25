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
    @State private var graph: BuildGraph = try! buildGraph(url: URL(fileURLWithPath:  "/Users/bartosz/Development/BuildG/DerivedData/BuildG/Build/Intermediates.noindex/XCBuildData/7f298f85ff0a7d4faa437918d6a25d9f.xcbuilddata/manifest.json")) //BuildGraph(nodes: [:])
    @State private var selection: String?
    @State private var focus: String?
    var body: some Scene {
        WindowGroup {
            var url: URL?
            let graphUrl = Binding(get: { url }, set: { newUrl in
                // TODO: recognize type (.xcodeproj, manifest.json, .xcbuilddata)
                guard let newUrlValue = ManifestLoader().findManifest(newUrl), let newGraph = try? buildGraph(url: newUrlValue) else {
                    return
                }
                DispatchQueue.main.async {
                    url = newUrlValue
                    graph = newGraph
                }
            })
            let webView = GraphWebView(graph: $graph, graphUrl: graphUrl, selection: $selection)
            ContentView(
                selection: $selection, focus: $focus, graph: $graph, graphUrl: graphUrl, web: webView
            )
        }
    }
}
