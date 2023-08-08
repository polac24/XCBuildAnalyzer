//
//  GraphItemView.swift
//  BuildAnalyzer
//
//  Created by Bartosz Polaczyk on 8/8/23.
//

import SwiftUI
import BuildAnalyzerKit

struct GraphItemRelationItem: View {
    @State private var didSelect:Bool = false
    @Binding var selection: BuildGraphNodeId?
    @Binding var focus: String?
    @Binding var globalSelection: String?

    let element: BuildGraphNodeId
    var body: some View {
        Text(element.id)
            .padding(.horizontal, 5)
            .help(element.id)
            .lineLimit(selection == element ? nil : 1)
            .truncationMode(.middle)
            .onTapGesture {
                if selection == element {
                    // double selection
                    focus = element.id
                    globalSelection = element.id
                }
                selection = element
            }
            .background(selection == element ? Color.blue : Color.clear)
    }
}

struct GraphItemDetailsSetView: View {
    let title: String
    let items: Set<BuildGraphNodeId>?
    @Binding var selection: BuildGraphNodeId?
    @Binding var focus: String?
    @Binding var globalSelection: String?

    var body: some View {
        if (items?.count ?? 0) > 0 {
            Divider()
            Text(title).bold()
            ForEach(Array(items ?? [])){ element in
                GraphItemRelationItem(selection: $selection, focus: $focus, globalSelection: $globalSelection, element: element)
            }
        }
    }
}

struct GraphItemView: View {
    let item: BuildGraphNode?
    @State var selection: BuildGraphNodeId? = nil
    @Binding var focus: String?
    @Binding var globalSelection: String?

    var body: some View {
        VStack {
            ScrollView{
                Text("Details")
                let itemTitle = item?.name ?? ""
                Text(itemTitle).bold()
                GraphItemDetailsSetView(title: "Inputs", items: item?.inputs, selection: $selection, focus: $focus, globalSelection: $globalSelection)
                GraphItemDetailsSetView(title: "Outputs", items: item?.outputs, selection: $selection, focus: $focus, globalSelection: $globalSelection)

            }
        }
    }
}

struct GraphItemView_Previews: PreviewProvider {
    static var previews: some View {
        GraphItemView(item: BuildGraphNode(id: .init(id: ""), tool: "tool", name: "Name", properties: [:], inputs: [], outputs: []), focus: .constant(nil), globalSelection: .constant(nil))
    }
}


extension BuildGraphNodeId: Identifiable {

}

//#Preview {
//    GraphItemView(item: BuildGraphNode(id: .init(id: ""), tool: "tool", name: "Name", properties: [:], inputs: [], outputs: []))
//}
