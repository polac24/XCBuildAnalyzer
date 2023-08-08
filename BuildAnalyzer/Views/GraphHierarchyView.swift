//
//  GraphHierarchyView.swift
//  BuildAnalyzer
//
//  Created by Bartosz Polaczyk on 6/19/23.
//

import Foundation
import SwiftUI
import Combine
import BuildAnalyzerKit


struct GraphHierarchyView: View {
    @Binding var selection: String?
    @Binding var focus: String?
    // Actual search (throttled)
    @Binding var search: String
    var graph: BuildGraph

    @State private var searchRaw: String = ""
    let searchTextPublisher = PassthroughSubject<String, Never>()
    private let items: [GraphHierarchyElement]

    init(
        selection: Binding<String?>,
        graph: BuildGraph,
        search: Binding<String>,
        focus: Binding<String?>
    ) {
        self._selection = selection
        self.graph = graph
        self._search = search
        self._focus = focus
        items = graph.build().compactMap {$0.filter(search.wrappedValue)}
    }

    var body: some View {
        VStack {
            List(graph.build().compactMap {$0.filter(search)}, children: \.items, selection: $selection) { row in
                Text(row.name)
                    .help(row.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .onTapGesture {
                        focus = row.id
                        selection = row.id
                    }
            }
            TextField("Search", text: $searchRaw)
                .padding(5)
                .onChange(of: searchRaw) { searchText in
                    searchTextPublisher.send(searchText)
                }
                .onReceive(
                    searchTextPublisher
                        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
                ) { debouncedSearchText in
                    self.search = debouncedSearchText
                }
        }
    }
}

extension BuildGraph {
    // TODO: extract to a separate class
    func build() -> [GraphHierarchyElement] {
        if let s = storage as? [GraphHierarchyElement] {
            return s
        }
        var types = [BuildGraphNode.Kind.Group: [(BuildGraphNodeId, BuildGraphNode)]]()

        for (nodeId, node) in nodes {
            let kind = node.kind.group
            var newArray = types[kind, default: []]
            newArray.append((nodeId, node))
            types[kind] = newArray
        }

        var result = [GraphHierarchyElement]()
        for (kind, elements) in types.sorted(by: {$0.key < $1.key} ) {
            let elements = elements.map { element in
                GraphHierarchyElement(id: element.0.id, name: element.1.name)
            }
            result.append(GraphHierarchyElement(id: "\(kind)", name: "\(kind)", items: elements))
        }
        storage = result
        return result
    }
}
