//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 8/12/23.
//

import Foundation

public struct BuildGraphNodeTimingIdExtra: Hashable {
    let nodeId: BuildGraphNodeId
    let type: String
}

public typealias BuildGraphNodeTimingId = BuildGraphNodeId

public struct BuildGraphNodeTiming: Hashable {
    public let node: BuildGraphNodeTimingId
    public let start: Double
    public let end: Double
    // 0 - 100% of the start in the entire build
    public let percentage: Double
}

public extension BuildGraphNodeTiming {
    var duration: Double {
        end - start
    }
}

public protocol BuildGraphNodeTimingReader {
    func read() throws -> [BuildGraphNodeTimingId: BuildGraphNodeTiming]
}
