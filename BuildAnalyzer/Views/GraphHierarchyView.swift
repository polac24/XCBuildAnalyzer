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
            result.append(GraphHierarchyElement(id: "\(kind)", name: "\(kind)", info: nil, items: elements))
        }
        storage = result
        return result
    }
}

extension BuildGraphNode.Kind {
    var humanDescription: String {
        switch self {
        case let .action(actionName: _, target: target, hash: _, name: name):
            // e.g. [MyTarget] will-sign
            return "[\(target)] \(name)"
        case let .targetAction(actionName: actionName, target: target, package: package, packageType: packageType, sdkRoot: sdkRoot, sdkVariant: sdkVariant, name: name):
            return "[\(target)] \(name) (\(packageType))"
        case let .artificial(id: id, target: target, name: name):
            return "[\(target)] \(id) \(name)"
        case let .file(path: path):
            return path
        case let .step(stepName: stepName, path: path):
            let pathURL = URL(fileURLWithPath: path)
            let pathDescription = path.count > 40 ?  ".../\(pathURL.pathComponents.suffix(5).joined(separator: "/"))" : path
            return "\(stepName) \(pathDescription)"
        case let .other(value: value):
            return value
        }
    }

    var subgroup: String? {
        switch self {
        case let .action(actionName: _, target: target, hash: _, name: _): return target
        case let .targetAction(actionName: _, target: target, package: _, packageType: _, sdkRoot: _, sdkVariant: _, name: _): return target
        default:
            return nil
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
