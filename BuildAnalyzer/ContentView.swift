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

    return BuildGraph(manifest: manifest)
}

struct ContentView: View {
    @State private var selection: String?
    @State private var search: String = ""
    let graph: BuildGraph
//    @State var projection: BuildGraphProjection
    @State var filteredItems: [GraphHierarchyElement]
//    @State var action: GraphViewRequestAction?
    let web: GraphWebView

    var body: some View {
        VStack {
            BuildsHistoryView()

            GeometryReader { geometry in
                HSplitView{
                    GraphHierarchyView(
                        selection: $selection,
                        graph: graph
                    )
                    //GraphWebView(graph: graph, selection: $selection)

                    web.layoutPriority(4).onChange(of: selection) { newValue in
                        web.controller.select(nodeId: newValue)
                    }.onAppear {
                        web.controller.coordinator.setBinding($selection)
                    }
                }
            }
        }
        .padding()
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            if let provider = providers.first(where: { $0.canLoadObject(ofClass: URL.self) } ) {
                let _ = provider.loadObject(ofClass: URL.self) { object, error in
                    if let url = object {
                        print("url: \(url)")

                        // TODO: recognize type (.xcodeproj, manifest.json, .xcbuilddata)
                        do {
                            let graph = try buildGraph(url: url)
                            print(graph.nodes)
                        } catch {
                            print(error)
                        }
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
