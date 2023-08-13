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
                selection = element
            }
            .background(selection == element ? Color.gray : Color.clear)
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
            Table(Array(items ?? [])){
                TableColumn(title){ element in
                    Text(element.id)
                        .padding(.horizontal, 5)
                        .help(element.id)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }.width(min: 1000)
            }
            .frame(minHeight: 200)

//            ForEach(Array(items ?? [])){ element in
//                GraphItemRelationItem(selection: $selection, focus: $focus, globalSelection: $globalSelection, element: element)
//            }
        }
    }
}


struct GraphItemDetailEnvView: View {
    let title: String
    private let tableValues: [EnvValue]

    private struct EnvValue: Identifiable {
        var id: String
        var value: String
    }

    init(title: String, values: [String: String]?){
        self.title = title
        self.tableValues = values?.map { key, value in
            EnvValue(id: key, value: value)
        } ?? []
    }

    var body: some View {
        if !tableValues.isEmpty {
            VStack{
                Divider()
                Text(title).bold()
                Table(tableValues) {
                    TableColumn("Key", value: \.id)
                    TableColumn("Value", value: \.value)
                }
                .tableStyle(.bordered(alternatesRowBackgrounds: false))
                .frame(minHeight: 100, maxHeight: 200)
                }
        }
    }
}

extension String: Identifiable {
    public var id: String {
        self
    }
}

struct GraphItemDetailView: View {
    let title: String
    let value: String?

    var body: some View {
        if let v = value, !v.isEmpty {
            Divider()
            Text(title).bold()
            Text(v)
        }
    }
}

struct GraphItemTimingView: View {
    let title: String
    let timing: BuildGraphNodeTiming?

    var body: some View {
        if let v = timing {
            Divider()
            Text(title).bold()
            Text("\(v.duration) s")
            Text("Start: \(v.start)")
            Text("End: \(v.end)")
            ProgressView(value: v.percentage ) { Text("\(Int(v.percentage * 100))% progress") }
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
                Text(item?.id.id ?? "")
                GraphItemDetailView(title: "Tool", value: item?.tool)
//                GraphItemDetailView(title: "Kind", value: item?.kind)
                GraphItemDetailEnvView(title: "ENVs", values: item?.env)
                GraphItemDetailsSetView(title: "Inputs", items: item?.inputs, selection: $selection, focus: $focus, globalSelection: $globalSelection)
                GraphItemDetailsSetView(title: "Outputs", items: item?.outputs, selection: $selection, focus: $focus, globalSelection: $globalSelection)
            }
            Divider()
            GraphItemTimingView(title: "Timing", timing: item?.timing)
        }
    }
}

struct GraphItemView_Previews: PreviewProvider {
    static var previews: some View {
        GraphItemView(item: BuildGraphNode(id: .init(id: ""), tool: "tool", name: "Name", properties: [:], inputs: [.init(id: "1111eee1sdajiodjasi doaijd oasidj aoidj osaidj asoidj asoidj aosidja sdioaj oasidj oaijd oiasjd oaisjd oaisjd oaisjd oaisjd oiasjd iasjod ij oi")], outputs: [], env: ["a":"B", "c": "Sssss"], timing: nil), focus: .constant(nil), globalSelection: .constant(nil))
    }
}


struct GraphItemDetailEnvView_Previews: PreviewProvider {
    static var previews: some View {
        GraphItemDetailEnvView(title: "AAA", values: ["a":"s"])
    }
}

extension BuildGraphNodeId: Identifiable {

}

//#Preview {
//    GraphItemView(item: BuildGraphNode(id: .init(id: ""), tool: "tool", name: "Name", properties: [:], inputs: [], outputs: []))
//}
