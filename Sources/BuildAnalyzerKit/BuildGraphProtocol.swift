//
//  File.swift
//  
//
//  Created by Bartosz Polaczyk on 6/18/23.
//

import Foundation


public protocol BuildGraphProtocol {
    var nodes: [BuildGraphNodeId: BuildGraphNode] { get }

    func expand(projection: BuildGraphProjection, with: BuildGraphProjectionExpansion) -> BuildGraphProjection
}
