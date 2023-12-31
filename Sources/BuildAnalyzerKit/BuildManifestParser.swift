//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import Foundation

public typealias BuildManifestTool = String
public typealias BuildManifestId = String

public struct BuildManifestCommand: Codable, Hashable {

    enum CodingKeys: String, CodingKey {
        case tool
        case inputs
        case outputs
        case expectedOutputs
        case roots
        case env
        case description
        case args
        case signature
        case workingDirectory = "working-directory"
        case alwaysOutOfDate = "always-out-of-date"
    }

    var tool: BuildManifestTool
    var inputs: [String]?
    var outputs: [String]?
    var expectedOutputs: [String]?
    var roots: [String]?
    var env: [String: String]?
    var description: String?
    var args: [String]?
    var signature: String?
    var workingDirectory: String?
    var alwaysOutOfDate: Bool?
}

public struct BuildManifestClient: Codable {
    let version: Int
    let name: String
}

public struct BuildManifest: Codable {
    let client: BuildManifestClient
    /// Actually all nodes
    let commands: [String: BuildManifestCommand]
    /// All targets that are requested
    let targets: [String: [String]]

    public init(
        client: BuildManifestClient,
        commands: [String : BuildManifestCommand],
        targets: [String: [String]]
    ) {
        self.commands = commands
        self.client = client
        self.targets = targets
    }
}

public class BuildManifestParser {
    private let decoder: JSONDecoder

    public init() {
        decoder = JSONDecoder()
    }

    public func process(_ path: String) throws -> BuildManifest {
        return try process(URL(fileURLWithPath: path))
    }

    public func process(_ url: URL) throws -> BuildManifest {
        let data = try Data(contentsOf: url)
        return try decoder.decode(BuildManifest.self, from: data)
    }
}
