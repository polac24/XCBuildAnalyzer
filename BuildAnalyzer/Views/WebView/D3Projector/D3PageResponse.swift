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
