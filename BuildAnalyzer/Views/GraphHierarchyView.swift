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
    @State var viewSelection: String?

    @State private var searchRaw: String = ""
    let searchTextPublisher = PassthroughSubject<String, Never>()
    private let items: [GraphHierarchyElement]

    init(
        selection: Binding<String?>,
        graph: BuildGraph,
        search: Binding<String>,
        focus: Binding<String?>
    ) {
        viewSelection = selection.wrappedValue
        self._selection = selection
        self.graph = graph
        self._search = search
        self._focus = focus
        items = graph.build().compactMap {$0.filter(search.wrappedValue)}
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
                            focus = v
                            selection = v
                        }
                    if let info = row.info { Text(info).help("Exists in a cycle") }
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
            let elements = elements.sorted(by: {$0.1.kind.humanDescription < $1.1.kind.humanDescription}).map { element in
                let in_cycle = cycleNodes.contains(element.0)
                return GraphHierarchyElement(id: element.0.id, name: element.1.kind.humanDescription, info: in_cycle ? "⚠️" : nil)
            }
            result.append(GraphHierarchyElement(id: "\(kind)", name: "\(kind.groupDescription)", info: nil, items: elements))
        }
        storage = result
        return result
    }
}

extension BuildGraphNode.Kind {
    var humanDescription: String {
        switch self {
        case let .simpleStep(stepName: stepName, file: file):
            return "[\(stepName)] \(file)"
        case let .file(path: path):
            return path
        case let .triggerStep(stepName: stepName, args: args):
            return "[\(stepName)] Trigger \(args.joined(separator: " "))"
        case .end:
            return "end"
        case let .complexStep(stepName: stepName, target: target):
            return "[\(target)] \(stepName)"
        case let .packageProductStep(stepName: stepName, target: target):
            return "[\(target)] \(stepName) (ProductStep)"
        case let .packageTargetStep(stepName: stepName, target: target):
            return "[\(target)] \(stepName) (TargetStep)"
        case let .gate(index: _, kind: kind):
            return "Gate \(kind.humanDescription)"
        case let .artificial(stepName: stepName, args: args):
            return "[\(stepName)] \(args.joined(separator: " "))"
        case let .other(value: value):
            return value
        }
    }
}

extension Array {
    func groupBy<Group: Hashable>(_ block: (Element) -> Group) -> [Group: [Element]] {
        var result: [Group: [Element]] = [:]
        for element in self {
            let group = block(element)
            let newElements = result[group, default: []] + [element]
        }
        return result
    }
}


extension BuildGraphNode.Kind.Group {
    var groupDescription: String {
        switch self {
        case .file: return "Files"
        case .other: return "Others"
        case .simpleStep: return "Simple steps"
        case .triggerStep: return "Trigger steps"
        case .end: return "End"
        case .complexStep: return "Complex steps"
        case .packageProductStep: return "Package Product steps"
        case .packageTargetStep: return "Package target steps"
        case .gate: return "Gates"
        case .artificial: return "Artificial"
        }
    }
}
