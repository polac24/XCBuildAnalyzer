//
//  GraphHierarchyHelpers.swift
//  BuildAnalyzer
//
//  Created by Bartosz Polaczyk on 9/7/23.
//

import Foundation
import BuildAnalyzerKit

protocol GraphHierarchyContentBuilderProtocol {
    func build(from graph: BuildGraphProtocol) -> [GraphHierarchyElement]
}

protocol GraphHierarchyGroup: Hashable, Comparable {
    var title: String { get }
    static func build(from: BuildGraphNode.Kind) -> Self
}

class GraphHierarchyContentBuilder<Group: GraphHierarchyGroup>: GraphHierarchyContentBuilderProtocol {
    private var cache: (BuildGraphProtocol, [GraphHierarchyElement])?

    func build(from graph: BuildGraphProtocol) -> [GraphHierarchyElement] {
        // cache hierarchy to not rebuild it all the time
        if let cached = cache, cached.0 === graph {
            return cached.1
        }
        var types = [Group: [(BuildGraphNodeId, BuildGraphNode)]]()

        for (nodeId, node) in graph.nodes {
            let kind = Group.build(from: node.kind)
            var newArray = types[kind, default: []]
            newArray.append((nodeId, node))
            types[kind] = newArray
        }

        var result = [GraphHierarchyElement]()
        for (kind, elements) in types.sorted(by: {$0.key < $1.key} ) {
            let elements = elements.sorted(by: {$0.1.kind.humanDescription < $1.1.kind.humanDescription}).map { element in
                var info = GraphHierarchyElementInfo(rawValue: 0)
                if graph.cycleNodes.contains(element.0) {
                    info = [info, .inCycle]
                }
                if graph.nodes[element.0]?.timing != nil {
                    info = [info, .active]
                }
                return GraphHierarchyElement(id: element.0.id, name: element.1.kind.humanDescription, info: info)
            }
            let allInfos: GraphHierarchyElementInfo = elements.map(\.info).compactMap({$0}).reduce([]) { info, element in
                return [element, info]
            }
            result.append(GraphHierarchyElement(id: "\(kind)", name: "\(kind.title)", info: allInfos, items: elements))
        }
        cache = (graph, result)
        return result
    }
}

struct GraphHierarchyTargetGroup: GraphHierarchyGroup {
    var title: String
    init(title: String) {
        self.title = title
    }

    static func build(from node: BuildAnalyzerKit.BuildGraphNode.Kind) -> GraphHierarchyTargetGroup {
        switch node {
        case .command(_,_, let target) where !target.isEmpty,
                .packageResource(_, let target),
                .complexStep(_, let target),
                .packageProductStep(_, let target),
                .packageTargetStep(_, let target): return .init(title: "[\(target)]")
        case .command(let stepName, _, _),
                .simpleStep(let stepName, _),
                .triggerStep(let stepName, _): return .init(title: stepName)
        case .end: return .init(title: "Ends")
        case .file(_): return .init(title: "Files")
        case .gate(_, let kind): return build(from: kind)
        case .other: return .init(title: "Others")
        }
    }
    
    static func < (lhs: GraphHierarchyTargetGroup, rhs: GraphHierarchyTargetGroup) -> Bool {
        lhs.title < rhs.title
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
        case let .complexStep(stepName: stepName, target: target),
                .packageResource(stepName: let stepName, target: let target):
            return "[\(target)] \(stepName)"
        case let .packageProductStep(stepName: stepName, target: target):
            return "[\(target)] \(stepName) (ProductStep)"
        case let .packageTargetStep(stepName: stepName, target: target):
            return "[\(target)] \(stepName) (TargetStep)"
        case let .gate(index: _, kind: kind):
            return "Gate \(kind.humanDescription)"
        case let .command(stepName: stepName, args: args, target: _):
            return "[\(stepName)] \(args.joined(separator: " "))"
        case let .other(value: value):
            return value
        }
    }
}
