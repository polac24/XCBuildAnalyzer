//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import Foundation

public typealias BuildManifestTool = String
public typealias BuildManifestId = String

public struct BuildCommandEdge: Hashable {
    let source: BuildManifestId
    let destination: BuildManifestId

    func reverse() -> Self {
        .init(source: destination, destination: source)
    }
}

public enum BuildManifestCommandType {
    public enum Kind: Hashable, Comparable {
        case action
        case step
        case artificial
        case file
        case unknown
    }

    case action(actionName: String, target: String, hash: String, name: String)
    case step(stepName: String, path: String)
    case artificial(id: String, name: String)
    case file(path: String)
    case unknown(value: String)

    public var kind:  Kind {
        switch self {
        case .action: return .action
        case .step: return .step
        case .artificial: return .artificial
        case .file: return .file
        case .unknown: return .unknown
        }
    }

    public static func build(command nodeName: BuildManifestId) throws -> Self {
        if let result = try /<(?<g1>[^-]+)-(?<g2>[^-]+)-(?<hash>.*)--(?<suf>.*)>/.firstMatch(in: nodeName) {
            // e.g. <target-AFr-f7c7f4eb947860cad1bd0ac8da2fbab7b297c560689668aabd8feed2d35e08a1--HeadermapTaskProducer>
            let o = result.output
            return .action(actionName: String(o.g1), target: String(o.g2), hash: String(o.hash), name: String(o.suf))
        } else if let result = try /<(?<action>\S+)[\ -](?<input>.*)>/.firstMatch(in: nodeName) {
            // e.g. <MkDir /Users/bartosz/Documents/wwdc2023/PP/DerivedData/PP/Build/Products/Debug-iphonesimulator/PP.app>
            let o = result.output
            return .step(stepName: String(o.action), path: String(o.input))
        } else if let result = try /P\d+:[^:]*:[^:]*:(?<action>\S+) ?(?<input>.*)/.firstMatch(in: nodeName) {
            // e.g. P0:::Gate target-PP-f7c7f4eb947860cad1bd0ac8da2fbab7ef7654ceda44fdc53d749a5dfb3f4596--ModuleMapTaskProducer
            let o = result.output
            return .artificial(id: String(o.action), name: String(o.input))
        }else if nodeName.first == "/" {
            // e.g. Users/bartosz/Documents/wwdc2023/PP/DerivedData/PP/Build/Intermediates.noindex/PP.build/Debug-iphonesimulator/AFr.build/AFr-project-headers.hmap
            return  .file(path: nodeName)
        }
        return .unknown(value: nodeName)
    }
}

public struct BuildManifestCommand: Codable, Hashable {
    let tool: BuildManifestTool
    var inputs: [String]?
    var outputs: [String]?
    let expectedOutputs: [String]?
    let roots: [String]?
}

public extension BuildManifest {
    func getAllNodes() ->  [BuildManifestId: BuildManifestCommand] {
        var visitedNodes = commands
        for (commandName, command) in commands {
            // inputs
            for inputName in command.inputs ?? [] {
                var input = visitedNodes[inputName, default: .init(tool: "file", inputs: [], outputs: [], expectedOutputs: nil, roots: nil)]
                input.outputs = (input.outputs ?? [] ) + [commandName]
                visitedNodes[inputName] = input
            }

            // outputs
            for outputName in command.outputs ?? [] {
                var output = visitedNodes[outputName, default: .init(tool: "file", inputs: [], outputs: [], expectedOutputs: nil, roots: nil)]
                output.inputs = (output.inputs ?? [] ) + [commandName]
                visitedNodes[outputName] = output
            }
        }
        return visitedNodes
    }
    func filterWith(edges: Set<BuildCommandEdge>) -> Self {
        var visitedNodes = [BuildManifestId: BuildManifestCommand]()
        for edge in edges {
            // first define a source with new/added output
            if let fullCommandSource = commands[edge.source] {
                var source = visitedNodes[edge.source, default: .init(tool: fullCommandSource.tool, inputs: [], outputs: [], expectedOutputs: fullCommandSource.expectedOutputs, roots: fullCommandSource.roots)]
                source.outputs?.append(edge.destination)
                visitedNodes[edge.source] = source
            }

            // destination with new/added inputs
            if let fullCommandDest = commands[edge.destination] {
                var destination = visitedNodes[edge.destination, default: .init(tool: fullCommandDest.tool, inputs: [], outputs: [], expectedOutputs: fullCommandDest.expectedOutputs, roots: fullCommandDest.roots)]
                destination.inputs?.append(edge.source)
                visitedNodes[edge.destination] = destination
            }
        }

        // add ?
//        var allNodes = getAllNodes()//[BuildManifestId: BuildManifestCommand]()

        for visited in visitedNodes.keys {
            guard let original = commands[visited] else {
                continue
            }
            if original.inputs?.count ?? 0 != visitedNodes[visited]!.inputs?.count ?? 0 {
                let newKey = "\(visited)_i_??"
                visitedNodes[visited]!.inputs?.append(newKey)
                visitedNodes[newKey] = BuildManifestCommand(tool: "", expectedOutputs: nil, roots: nil)
            }

            if original.outputs?.count ?? 0 != visitedNodes[visited]!.outputs?.count ?? 0 {
                let newKey = "\(visited)_o_??"
                visitedNodes[visited]!.outputs?.append(newKey)
                visitedNodes[newKey] = BuildManifestCommand(tool: "", expectedOutputs: nil, roots: nil)
            }
        }
        return Self.init(commands: visitedNodes)
    }
}


public struct BuildManifest: Codable {

//    let client: BuildManifestClient
//    let targets: [String: [String]]
//    let nodes: [String: BuildManifestNode]
    let commands: [String: BuildManifestCommand]
    public init(commands: [String : BuildManifestCommand]) {
        self.commands = commands
    }
}

public class BuildManifestParser {
    private let decoder: JSONDecoder

    public init() {
        decoder = JSONDecoder()
    }

    public func process(_ path: String) throws -> BuildManifest {
        let data = try Data(contentsOf: URL(filePath: path))
        return try decoder.decode(BuildManifest.self, from: data)
    }
}
