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
    @State private var graph: BuildGraph = .empty //try! buildGraph(url: URL(fileURLWithPath:  "/Users/bartosz/Development/BuildG/DerivedData/BuildG/Build/Intermediates.noindex/XCBuildData/7f298f85ff0a7d4faa437918d6a25d9f.xcbuilddata/manifest.json")) //BuildGraph(nodes: [:])
    @State private var selection: String?
    @State private var focus: String?
    private let manifestFinder = ManifestFinder()
    var body: some Scene {
        WindowGroup {
            var url: URL?
            let graphUrl = Binding(get: { url }, set: { newUrl in
                // TODO: recognize type (.xcodeproj, manifest.json, .xcbuilddata)
                guard let inputUrl = newUrl, let newUrlManifest = try? manifestFinder.findLatestManifest(options: .build(xcodeproj: inputUrl)), let newGraph = try? buildGraph(url: newUrlManifest.manifest) else {
                    return
                }
                
                DispatchQueue.main.async {
                    url = newUrlManifest.manifest
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
