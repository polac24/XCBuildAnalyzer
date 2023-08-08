//
//  ContentView.swift
//  BuildAnalyzer
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import SwiftUI
import GraphKit
import BuildAnalyzerKit

class BuildGraphModel : ObservableObject {
    var buildGraph: BuildGraph

    init(buildGraph: BuildGraph) {
        self.buildGraph = buildGraph
    }

    func change(_ buildGraph : BuildGraph) {
        self.buildGraph = buildGraph
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}



func buildGraph(url: URL) throws -> BuildGraph {
    let parser = BuildManifestParser()
    let manifest = try parser.process(url)

    return BuildGraph(manifest: manifest)
}

struct ContentView: View {
    @Binding private var selection: String?
    @State private var readFile: URL?
//    @Binding var graph: BuildGraph
    private var web: GraphWebView
    var graph: BuildGraph



    init(selection: Binding<String?>) {
//        self.selection = nil
//        self.readFile = nil
        let graph = try! buildGraph(url: URL(fileURLWithPath:  "/Users/bartosz/Development/BuildG/DerivedData/BuildG/Build/Intermediates.noindex/XCBuildData/7f298f85ff0a7d4faa437918d6a25d9f.xcbuilddata/manifest.json"))
        let web = GraphWebView(graph: graph)
        //        self.graph = graph
        self.web = web
        self.graph = graph
        _selection = selection
    }
    
    var body: some View {
        VStack {
            BuildsHistoryView()
            GeometryReader { geometry in
                HSplitView{
                    GraphHierarchyView(
                        selection: $selection,
                        graph: graph
                    ).frame(minWidth: 200, maxWidth: 400)

                    web.layoutPriority(10).onChange(of: selection) { newValue in
                        web.controller.select(nodeId: newValue)
                    }.onAppear() {
                        web.controller.coordinator.setBinding($selection)
                    }
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            if let provider = providers.first(where: { $0.canLoadObject(ofClass: URL.self) } ) {
                let _ = provider.loadObject(ofClass: URL.self) { object, error in
                    if let url = object {
                        print("url: \(url)")

                        // TODO: recognize type (.xcodeproj, manifest.json, .xcbuilddata)
                            //        self.graph = graph
//                        self.graph = try! buildGraph(url: url)
                            DispatchQueue.main.async {
                                do {
//                                    readFile = url
//                                    self.web = GraphWebView(graph: graph)
                                } catch {
                                    print(error)
                                }
                            }
                        //                            graph.change(bg)

//                            print(graph.nodes)
                    }
                }
                return true
            }
            return false
        }//.id(readFile?.absoluteString ?? "")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Text("a")
        //        ContentView(graph: BuildGraph(), projection: )
    }
}
