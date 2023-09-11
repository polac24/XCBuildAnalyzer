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
    @State private var graph: BuildGraph = .empty
    @State private var selection: Set<String> = []
    @State private var focus: String?
    private static let DefaultTitle = "XCBuildAnalyzer"
    @State private var windowTitle = Self.DefaultTitle
    private let manifestFinder = ManifestFinder()
    var body: some Scene {
        Window(Self.DefaultTitle, id: "MainWindow") {
            var url: URL?
            let graphUrl = Binding(get: { url }, set: { newUrl in
                guard let inputUrl = newUrl, let newUrlManifest = try? manifestFinder.findLatestManifest(options: .build(project: inputUrl)), let newGraph = try? buildGraph(manifestLocation: newUrlManifest) else {
                    return
                }
                
                DispatchQueue.main.async {
                    url = newUrlManifest.manifest
                    windowTitle = newUrlManifest.projectFile?.absoluteString ?? Self.DefaultTitle
                    graph = newGraph
                    selection = []
                    focus = nil
                }
            })
            let webView = GraphWebView(graph: $graph, graphUrl: graphUrl, selection: $selection, focus: $focus)
            AppView(
                selection: $selection, focus: $focus, graph: $graph, graphUrl: graphUrl, web: webView
            )
        }
    }
}
