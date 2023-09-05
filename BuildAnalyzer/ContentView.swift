//
//  ContentView.swift
//  BuildAnalyzer
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import SwiftUI
import GraphKit
import BuildAnalyzerKit


func buildGraph(url: URL) throws -> BuildGraph {
    let parser = BuildManifestParser()
    let manifest = try parser.process(url)

    // TODO: Enable reliable timings which provide valuable timestamps
/*
    let dbUrl = url.deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("build.db")
    let timingReader = BuildGraphNodeTimingSqlReader(file: dbUrl)
    let timing = try timingReader.read()
 */
    return BuildGraph(manifest: manifest, timings: [:])
}

struct ContentView: View {
    @Binding var selection: String?
    @Binding var focus: String?
    @State private var search: String = ""
    @Binding var graph: BuildGraph
    @Binding var graphUrl: URL?
    let web: GraphWebView

    var body: some View {
        VStack {
            GeometryReader { geometry in
                HSplitView{
                    GraphHierarchyView(
                        selection: $selection,
                        graph: graph,
                        search: $search,
                        focus: $focus
                    ).frame(minWidth: 300)

                    ZStack(alignment: .topLeading) {
                        web.onChange(of: focus) { newValue in
                            web.controller.select(nodeId: newValue)
                        }.onChange(of: graph) { newValue in
                            web.controller.reset()
                            selection = nil
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
                        item: graph.nodes[BuildGraphNodeId(id: selection ?? "")], focus: $focus, globalSelection: $selection
                    ).frame(minWidth: 300)
                }
            }
        }
        .padding()
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            if let provider = providers.first(where: { $0.canLoadObject(ofClass: URL.self) } ) {
                let _ = provider.loadObject(ofClass: URL.self) { object, error in
                    if let url = object {
                        print("url: \(url)")
                        graphUrl = url
                    }
                }
                return true
            }
            return false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Text("a")
        //        ContentView(graph: BuildGraph(), projection: )
    }
}
