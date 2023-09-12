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
    @State private var presentationError: ManifestFinderError?
    @State private var loading: Bool = false

    var body: some Scene {
        Window(Self.DefaultTitle, id: "MainWindow") {
            var url: URL?
            let graphUrl = Binding(get: { url }, set: { newUrl in
                guard !loading else {
                    return
                }
                loading = true
                Task.detached {
                    do {
                        guard let inputUrl = newUrl, let newUrlManifest = try manifestFinder.findLatestManifest(options: .build(project: inputUrl)) else {
                            return
                        }

                        let newGraph = try buildGraph(manifestLocation: newUrlManifest)
                        DispatchQueue.main.async {
                            url = newUrlManifest.manifest
                            windowTitle = newUrlManifest.projectFile?.absoluteString ?? Self.DefaultTitle
                            graph = newGraph
                            selection = []
                            focus = nil
                            loading = false
                        }
                    } catch let error as ManifestFinderError {
                        presentationError = error
                        loading = false
                        return
                    } catch {
                        presentationError = .otherError(error)
                        loading = false
                        return
                    }
                }
            })
            let webView = GraphWebView(graph: $graph, graphUrl: graphUrl, selection: $selection, focus: $focus)
            AppView(
                selection: $selection, focus: $focus, graph: $graph, graphUrl: graphUrl, web: webView, error: $presentationError, loading: $loading
            )
        }
    }
}
