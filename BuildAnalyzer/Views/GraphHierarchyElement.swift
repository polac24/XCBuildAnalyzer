//
//  GraphHierarchyElement.swift
//  BuildAnalyzer
//
//  Created by Bartosz Polaczyk on 6/19/23.
//

import Foundation

struct GraphHierarchyElement: Identifiable, Equatable {
    let id: String
    let name: String
    var items: [GraphHierarchyElement]?
}


extension GraphHierarchyElement {
    func filter(_ string: String) -> GraphHierarchyElement? {
        guard string != "" else { return self }
        guard items != nil else {
            // do not modify unnecessary
            return name.contains(string) ? self : nil
        }
        var include = false
        var children = (items ?? []).compactMap( { $0.filter(string) })
        if children.count > 0 || name.contains(string) {
            return .init(id: name, name: name, items: children)
        }
        return nil
    }
}
