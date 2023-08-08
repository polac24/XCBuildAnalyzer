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
    // Actual search (throttled)
    @State var search: String = ""
    private var graph:  BuildGraph

    @State private var searchRaw: String = ""
    let searchTextPublisher = PassthroughSubject<String, Never>()
    private let items: [GraphHierarchyElement]
    @Binding private var filteredItems: [GraphHierarchyElement]

    init(
        selection: Binding<String?>,
        graph: BuildGraph
    ) {
        self._selection = selection
        self.graph = graph
        let allItems = GraphHierarchyView.build(graph.nodes)
        items = allItems
        _filteredItems = Binding.constant(allItems)
        filteredItems = allItems
    }

    var body: some View {
        VStack {
            List(filteredItems, children: \.items, selection: $selection) { row in
                Text(row.name)
                    .help(row.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .onTapGesture {
                        selection = row.id
                    }
            }
            Text("\(filteredItems.count)")
            Text("\(items.count)")
            Text("\(graph.nodes.count)")
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
                    self.filteredItems = items.compactMap {$0.filter(debouncedSearchText)}
                }
        }
    }
}

private extension GraphHierarchyView {
    // TODO: extract to a separate class
    static func build(_ graph: [BuildGraphNodeId: BuildGraphNode]) -> [GraphHierarchyElement] {
        var types = [BuildGraphNode.Kind.Group: [(BuildGraphNodeId, BuildGraphNode)]]()

        for (nodeId, node) in graph {
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
        return result
    }
}
