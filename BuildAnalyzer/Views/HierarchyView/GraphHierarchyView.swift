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


// Represent left pane - a list of nodes in a graph aggregated by types
struct GraphHierarchyView: View {
    @Binding var selection: Set<String>
    @Binding var focus: String?
    // Actual search (throttled)
    @Binding var search: String
    var graph: BuildGraph
    @State var viewSelection: Set<String>

    @State private var searchRaw: String = ""
    let searchTextPublisher = PassthroughSubject<String, Never>()
    private let items: [GraphHierarchyElement]

    init(
        selection: Binding<Set<String>>,
        graph: BuildGraph,
        search: Binding<String>,
        focus: Binding<String?>,
        hierarchyBuilder: GraphHierarchyContentBuilderProtocol
    ) {
        viewSelection = selection.wrappedValue
        self._selection = selection
        self.graph = graph
        self._search = search
        self._focus = focus
        items = hierarchyBuilder.build(from: graph).compactMap {$0.filter(search.wrappedValue)}
    }

    var body: some View {
        VStack {
            List(items, children: \.items, selection: $viewSelection) { row in
                HStack {
                    
                    Text(row.name)
                        .help(row.name)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .onChange(of: viewSelection) { v in
                            focus = v.first
                            selection = v
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if row.info?.contains(.active) == true { Image(systemName: "hammer.circle").help("Executed in a last build") }
                    if row.info?.contains(.inCycle) == true { Image(systemName: "exclamationmark.arrow.circlepath").help("Exists in a cycle") }
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
