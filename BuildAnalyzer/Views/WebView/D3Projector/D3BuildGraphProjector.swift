//
//  D3Projector.swift
//  BuildAnalyzer
//
//  Created by Bartosz Polaczyk on 6/25/23.
//

import Foundation
import BuildAnalyzerKit

protocol BuildGraphProjector {
    func build() -> String
}

typealias D3BuildGraphNodeId = String

class D3BuildGraphProjector: BuildGraphProjector {
    private(set) var buildGraphNodesMapping: [BuildGraphNodeId: D3BuildGraphNodeId]
    // reverse mapping
    // TODO: validate if really needed
    private(set) var d3GraphNodesMapping: [D3BuildGraphNodeId: BuildGraphNodeId]


    private var edges: [(BuildGraphNodeProjectionNode, BuildGraphNodeProjectionNode)] = []
    private let projection: BuildGraphProjection

    init(projection: BuildGraphProjection, buildGraphNodesMapping: [BuildGraphNodeId: D3BuildGraphNodeId] = [:]) {
        self.projection = projection
        self.buildGraphNodesMapping = buildGraphNodesMapping
        d3GraphNodesMapping = buildGraphNodesMapping.reduce(into: [:], { partialResult, next in
            partialResult[next.value] = next.key
        })

    }

    func build() -> String  {
        for node in projection.nodes.values.sorted(by: { lhs, rhs in
            lhs.level == rhs.level ? (lhs.node.id < rhs.node.id) : (lhs.level < rhs.level)
        }) {
            defineNode(node: node)
        }

        for node in projection.nodes.values.sorted() {
            for input in node.inputNodes.sorted(by: {$0.id < $1.id}) {
                defineEdge(source: projection.nodes[input]!, destination: node)
            }
            for output in node.outputNodes.sorted(by: {$0.id < $1.id}) {
                defineEdge(source: node, destination: projection.nodes[output]!)
            }
        }

        return generate()
    }

    private func defineEdge(source: BuildGraphNodeProjectionNode, destination: BuildGraphNodeProjectionNode) {
        edges.append((source, destination))
    }

    @discardableResult
    private func defineNode(node: BuildGraphNodeProjectionNode) -> D3BuildGraphNodeId {
        let name = node.node
        guard let reference = buildGraphNodesMapping[name] else {
            let reference = "N\(buildGraphNodesMapping.count)"
            buildGraphNodesMapping[name] = reference
            d3GraphNodesMapping[reference] = name
            return reference
        }
        return reference
    }

    private func generate() -> String {
        var result: [String] = []

        for node in projection.nodes.values.sorted(by: {$0.node.id < $1.node.id} ){
            let isSelected = node.highlighted
            let d3Reference = buildGraphNodesMapping[node.node]!
            // TODO: refactor to a better abstraction
            let label = buildTableLabel(node: node)
            result.append("  \(d3Reference) [tooltip=\"\(node.node.id)\", xlabel=\"\", xlp=\"-20,-20\", label=\(label)\(isSelected ? ",color=\"#394662\"" : "color=\"none\"")];")
        }

        for edge in edges.sorted(by: {$0.0 == $1.0 ? ($0.1 < $1.1 ) : $0.0 < $1.0 }) {
            let source = buildGraphNodesMapping[edge.0.node]!
            let destination = buildGraphNodesMapping[edge.1.node]!
            let selected = projection.highlightedEdges.contains(.init(source: edge.1.node, destination: edge.0.node))
            result.append("  \(source) -> \(destination) \(selected ? "[color=\"#EED036\"]" :"" );")
        }
        return result.joined(separator: " ")
    }

    private func iconImage(node: BuildGraphNodeProjectionNode) -> String {
        var path = "img/"
        switch BuildGraphNode.Kind.generateKind(name: node.node.id) {
        case .file:
            path += "doc"
        case .simpleStep:
            path += "cube.transparent"
        case .complexStep:
            path += "cube.fill"
        case .triggerStep:
            path += "pyramid"
        case .packageProductStep:
            path += "cone"
        case .packageTargetStep:
            path += "cone.fill"
        case .command:
            path += "shipping"
        case .gate:
            path += "gate"
        case .other:
            path += "question"
        case .end:
            path += "stop"
        default:
            path += "cube"
        }
        switch (node.hidesSomeInputs, node.hidesSomeOutputs) {
        case (true, true):
            path += "_in_out.svg"
        case (true, _):
            path += "_in.svg"
        case (_, true):
            path += "_out.svg"
        default:
            path += ".svg"
        }
        return path
    }

    private func buildTableLabel(node: BuildGraphNodeProjectionNode) -> String {
        "<<table border=\"0\" cellborder=\"0\" cellspacing=\"1\"><TR><TD><IMG SRC=\"\(iconImage(node: node))\"/></TD></TR><tr><td>\(safeHtmlName(buildLabel(nodeName: BuildGraphNode.Kind.generateKind(name: node.node.id).humanDescription)))</td></tr></table>>"
    }

    private func safeHtmlName(_ name: String) -> String {
        var result = name.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of:"\"", with: "&quot;")
        result = result.replacingOccurrences(of:"'", with: "&#39;")
        result = result.replacingOccurrences(of:"<", with: "&lt;")
        result = result.replacingOccurrences(of:">", with: "&gt;")
        // allow <br/>
        result = result.replacingOccurrences(of:"\n", with: "<br/>")
        return result
    }

    private func buildLabel(nodeName: String) -> String {
        nodeName.split(maxLen: 30, separator: "\n", maxBatches: 5)
    }
}


extension String {
    func split(maxLen: Int, separator: String, maxBatches: Int = 0) -> String {
        var left = Substring(self)
        var batches: [Substring] = []
        var batch: Substring = ""
        func action() {
            batch = left.prefix(maxLen)
            left = left.dropFirst(maxLen)
        }
        action()
        while !batch.isEmpty {
            batches.append(batch)
            action()
        }
        if maxBatches > 0 {
            let takeCount = min(batches.count, maxBatches)
            let prefixCount = takeCount / 2
            let suffixCount = takeCount - prefixCount
            var ellipsis: [Self.SubSequence] = []
            if takeCount < batches.count {
                ellipsis = ["..."]
            }
            batches = batches.prefix(upTo: prefixCount) + ellipsis + batches.suffix(suffixCount)
        }
        return batches.joined(separator: separator)
    }
}
