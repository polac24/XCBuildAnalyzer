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
//    @State var graph: BuildGraph = BuildGraph(nodes: [:])
    @State var graph: BuildGraph = try! buildGraph(url: URL(fileURLWithPath:  "/Users/bartosz/Development/BuildG/DerivedData/BuildG/Build/Intermediates.noindex/XCBuildData/7f298f85ff0a7d4faa437918d6a25d9f.xcbuilddata/manifest.json"))
    @State var selection: String?

    var body: some Scene {
        WindowGroup {
            let url = URL(fileURLWithPath:  "/Users/bartosz/Development/BuildG/DerivedData/BuildG/Build/Intermediates.noindex/XCBuildData/7f298f85ff0a7d4faa437918d6a25d9f.xcbuilddata/manifest.json")
//            let url = URL(fileURLWithPath:  "/Users/bartosz/Development/XCRemoteCache/DerivedData/XCRemoteCache/Build/Intermediates.noindex/XCBuildData/53f08ae49373f91cf4be12601112d99e.xcbuilddata/manifest.json")
//            let graph = try! buildGraph(url: url)
//            let graph = try! buildGraph(url: url)
//            let graph = BuildGraph(nodes: [:])
//            let webView = GraphWebView(graph: graph)
            ContentView(
                selection: $selection
            ).id("")
        }
    }
}
