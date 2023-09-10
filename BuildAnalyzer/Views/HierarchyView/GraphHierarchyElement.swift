//
//  GraphHierarchyElement.swift
//  BuildAnalyzer
//
//  Created by Bartosz Polaczyk on 6/19/23.
//

import Foundation

struct GraphHierarchyElementInfo: OptionSet {
    let rawValue: Int

    static let inCycle = GraphHierarchyElementInfo(rawValue: 1 << 0)
    static let active = GraphHierarchyElementInfo(rawValue: 1 << 1)
}

struct GraphHierarchyElement: Identifiable, Equatable {
    let id: String
    let name: String
    let info: GraphHierarchyElementInfo?
    var items: [GraphHierarchyElement]?
}

extension GraphHierarchyElement {
    func filter(_ string: String) -> GraphHierarchyElement? {
        guard string != "" else { return self }
        guard items != nil else {
            // do not modify unnecessary
            return filter(search: string) ? self : nil
        }
        let children = (items ?? []).compactMap( { $0.filter(string) })
        if children.count > 0 || filter(search: string) {
            return .init(id: name, name: name, info: info, items: children)
        }
        return nil
    }

    private func filter(search: String) -> Bool {
        return name.lowercased().contains(search.lowercased())
    }
}
