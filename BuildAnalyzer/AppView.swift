//
//  ContentView.swift
//  BuildAnalyzer
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import SwiftUI
import GraphKit
import BuildAnalyzerKit


func buildGraph(manifestLocation: ManifestLocation) throws -> BuildGraph {
    let parser = BuildManifestParser()
    let manifest = try parser.process(manifestLocation.manifest)
    let timings = try manifestLocation.timingDatabase.flatMap(BuildGraphNodeTimingSqlReader.init(file:))?.read() ?? [:]

    // TODO: Enable reliable timings which provide valuable timestamps
    return BuildGraph(manifest: manifest, timings: timings)
}

struct AppView: View {
    @Binding var selection: Set<String>
    @Binding var focus: String?
    @State private var search: String = ""
    @Binding var graph: BuildGraph
    @Binding var graphUrl: URL?
    let web: GraphWebView
    private let hierarchyBuilder = GraphHierarchyContentBuilder<GraphHierarchyTargetGroup>()
    @Binding var error: ManifestFinderError?
    @Binding var loading: Bool

    var body: some View {
        ZStack {
            VStack {
                GeometryReader { geometry in
                    HSplitView{
                        GraphHierarchyView(
                            selection: $selection,
                            graph: graph,
                            search: $search,
                            focus: $focus,
                            hierarchyBuilder: hierarchyBuilder
                        ).frame(minWidth: 300).padding(.horizontal)

                        ZStack(alignment: .topLeading) {
                            web.onChange(of: selection) { newValue in
                                web.controller.select(nodes: newValue, focus: focus)
                            }.onChange(of: graph) { newValue in
                                web.controller.reset()
                                selection = []
                            }.onAppear {
                                web.controller.coordinator.setBinding($selection)
                            }

                            Button<Text>("◎") {
                                web.controller.resetZoom()
                            }
                            .help("Reset zoom")
                            .padding(5)
                            .opacity(graph.nodes.isEmpty ? 0 : 1)
                        }.layoutPriority(1000)

                        GraphItemView (
                            item: graph.nodes[BuildGraphNodeId(id: ($focus.wrappedValue ?? ""))], focus: $focus
                        ).frame(minWidth: 300)
                    }
                }
            }
            .padding()
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                if let provider = providers.first(where: { $0.canLoadObject(ofClass: URL.self) } ) {
                    let _ = provider.loadObject(ofClass: URL.self) { object, error in
                        if let url = object {
                            graphUrl = url
                        }
                    }
                    return true
                }
                return false
            }
            if loading {
                Rectangle()
                    .fill(Color.black.opacity(0.4))
                ProgressView()
            }
        }.errorAlert(error: $error)
    }
}
