//
//  D3PageResponse.swift
//  BuildAnalyzer
//
//  Created by Bartosz Polaczyk on 6/25/23.
//

import Foundation


struct D3PageResponse: Decodable {
    enum Message: String, Decodable {
        case selected
        case expandIn
        case expandOut
    }
    let msg: Message
    let id: String
}


struct D3PageRequest: Encodable {
    struct Option: Encodable {
        let reset: Bool

        static let noop = Option(reset: false)
    }

    var option: Option
    /// D3 graphiz content
    var graph: String?
    /// extra config of a digraph
    var extra: String?
    /// the id (e.g. N1) of the node that should be selected
    var highlight: String?
}
