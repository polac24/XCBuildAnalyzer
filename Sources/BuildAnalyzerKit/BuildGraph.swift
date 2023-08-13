//
//  File.swift
//
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import Foundation

// It might be a Date in the future, if the starting date can be fetched
public typealias BuildTiming = Double
public typealias BuildInterval = (start: BuildTiming, end: BuildTiming)


public class BuildGraph: BuildGraphProtocol, Equatable{
    public static func == (lhs: BuildGraph, rhs: BuildGraph) -> Bool {
        lhs.nodes == rhs.nodes
    }
    
    public private(set) var nodes: [BuildGraphNodeId: BuildGraphNode]
    public private(set) var cycles: [[BuildGraphNodeId]]
    // Might not be needed
    public private(set) var buildInterval: BuildInterval?

    // Hacky
    public var storage: [Any]? = nil

    public init(nodes: [BuildGraphNodeId: BuildGraphNode], cycles: [[BuildGraphNodeId]], buildInterval: BuildInterval?) {
        self.nodes = nodes
        self.cycles = cycles
        self.buildInterval = buildInterval
    }
}

public extension BuildGraph {
    convenience init(manifest: BuildManifest, timings: [BuildGraphNodeTimingId: BuildGraphNodeTiming] = [:]) {
        let nodes = Self.buildAllNodes(commands: manifest.commands, timings: timings)
        self.init(
            nodes: nodes,
            cycles: Self.findCycles(nodes),
            buildInterval: Self.buildInterval(timings: timings)
        )
    }
    
    private static func buildAllNodes(commands: [String: BuildManifestCommand], timings: [BuildGraphNodeTimingId: BuildGraphNodeTiming] ) ->  [BuildGraphNodeId: BuildGraphNode] {
        var visitedNodes: [BuildGraphNodeId: BuildGraphNode] = [:]
        for (commandName, command) in commands {
            let commandNodeId = BuildGraphNodeId(nodeName: commandName)
            
            // inputs
            let inputIds = (command.inputs ?? []).map { inputName in
                let nodeId = BuildGraphNodeId(nodeName: inputName)
                var input = visitedNodes[nodeId, default: .buildEmpty(id: nodeId, name: inputName)]
                input.outputs = input.outputs.union([commandNodeId])
                visitedNodes[nodeId] = input
                return nodeId
            }
            
            // outputs
            let outputIds = (command.outputs ?? []).map { outputName in
                let nodeId = BuildGraphNodeId(nodeName: outputName)
                var output = visitedNodes[nodeId, default: .buildEmpty(id: nodeId, name: outputName)]
                output.inputs = output.inputs.union([commandNodeId])
                visitedNodes[nodeId] = output
                return nodeId
            }
            
            // actual command node
            let node = BuildGraphNode(
                id: commandNodeId,
                tool: command.tool,
                name: commandName,
                properties: properties(from: command),
                inputs: Set(inputIds),
                outputs: Set(outputIds),
                env: command.env,
                timing: timings[commandNodeId]
            )
            visitedNodes[commandNodeId] = node
        }
        return visitedNodes
    }
    
    private static func findCycles(_ nodes: [BuildGraphNodeId: BuildGraphNode]) -> [[BuildGraphNodeId]] {
        struct State {
            var node: String
            var history: [String]
            var historySet: Set<String>
        }
        // optimized
        var nodeDeps: [String: [String]] = [:]
        for node in nodes {
            nodeDeps[node.key.id] = node.value.inputs.map(\.id)
        }
        var cycles: [[String]] = []
        var allNodesToTraverse = Set(nodes.keys.map(\.id))
        while let startingNode = allNodesToTraverse.first {
            var paths: [String?] = [startingNode]
            var history: [String] = []
            while let pathOptional = paths.popLast() {
                guard let path = pathOptional else {
                    let rem = history.removeLast()
                    allNodesToTraverse.remove(rem)
                    continue
                }
                let node = path
                if !allNodesToTraverse.contains(node) {
                    // we don't need to check it once again
                    continue
                }
                if let index = history.firstIndex(of: node) {
                    // we found a cycle
                    // TODO: trim the history to the cycle only
                    cycles.append(history[index...] + [node])
                    allNodesToTraverse.remove(node)
                    continue
                }
                history.append(node)
                paths.append(nil)
                for dependencyNode in nodeDeps[node]! {
                    paths.append(dependencyNode)
                }
            }
        }
        return cycles.map { cycle in
            cycle.map(BuildGraphNodeId.init(id:))
        }
    }
    
    private static func properties(from: BuildManifestCommand) -> [BuildGraphNode.Property: BuildGraphNode.PropertyValue] {
        // Implement reading all required and optional fields
        return [:]
    }
    
    private static func buildInterval(timings: [BuildGraphNodeTimingId: BuildGraphNodeTiming]) -> BuildInterval? {
        guard let max = timings.values.map(\.end).max(), let min = timings.values.map(\.start).min() else {
            return nil
        }
        return (start: min, end: max)
    }
}
