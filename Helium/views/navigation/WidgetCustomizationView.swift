//
//  WidgetCustomizationView.swift
//  Helium
//
//  Created by lemin on 10/13/23.
//

import Foundation
import SwiftUI

// MARK: Widget Customization View

struct WidgetCustomizationView: View {
    @StateObject var widgetManager: WidgetManager = .init()

    var body: some View {
        NavigationView {
            VStack {
                // List of Widget Sets
                List {
                    ForEach($widgetManager.widgetSets) { widgetSet in
                        NavigationLink(destination: EditWidgetSetView(widgetManager: widgetManager, widgetSet: widgetSet.wrappedValue)) {
                            Text(widgetSet.title.wrappedValue)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { i in
                            UIApplication.shared.confirmAlert(title: NSLocalizedString("Delete ", comment: "") + "\(widgetManager.widgetSets[i].title)", body: NSLocalizedString("Are you sure you want to delete the widget set ", comment: "") + "\"\(widgetManager.widgetSets[i].title)\"?", onOK: {
                                widgetManager.removeWidgetSet(widgetSet: widgetManager.widgetSets[i])
                            }, noCancel: false)
                        }
                    }
                }
                .toolbar {
                    HStack {
                        // create a new widget set
                        Button(action: {
                            UIApplication.shared.inputAlert(title: NSLocalizedString("Enter Name", comment: ""), body: NSLocalizedString("Choose a name for the widget set.", comment: ""), confirmTitle: NSLocalizedString("Confirm", comment: ""), placeholder: NSLocalizedString("Name", comment: ""), onOK: { title in
                                // make selection for anchor
                                UIApplication.shared.optionsAlert(title: NSLocalizedString("Choose Side", comment: ""), body: NSLocalizedString("Choose a side for the widget set to anchor to. This can be changed later.", comment: ""), options: [NSLocalizedString("Left", comment: ""), NSLocalizedString("Center", comment: ""), NSLocalizedString("Right", comment: "")]) { anchorSide in
                                    var anchor: Int
                                    switch anchorSide {
                                    case NSLocalizedString("Left", comment: ""):
                                        anchor = 0
                                    case NSLocalizedString("Center", comment: ""):
                                        anchor = 1
                                    case NSLocalizedString("Right", comment: ""):
                                        anchor = 2
                                    default:
                                        anchor = 0
                                    }
                                    widgetManager.createWidgetSet(title: title == "" ? NSLocalizedString("Untitled", comment: "") : title, anchor: anchor)
                                }
                            }, noCancel: false)
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .navigationTitle(Text(NSLocalizedString("Customize", comment: "")))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: Widget Add View

struct WidgetAddView: View {
    @StateObject var widgetManager: WidgetManager
    @State var widgetSet: WidgetSetStruct
    @Binding var isOpen: Bool

    var onChoice: (WidgetIDStruct) -> Void

    var body: some View {
        List {
            ForEach(WidgetModule.allCases, id: \.self) { id in
                Button(action: {
                    let newWidget = widgetManager.addWidget(widgetSet: widgetSet, module: id)
                    isOpen = false
                    onChoice(newWidget)
                }) {
                    WidgetChoiceView(widgetName: WidgetDetails.getWidgetName(id), exampleText: WidgetDetails.getWidgetExample(id))
                }
            }
        }
    }
}

// MARK: Widget Choice View

struct WidgetChoiceView: View {
    var widgetName: String
    var exampleText: String

    var body: some View {
        HStack {
            ZStack {
                Image(uiImage: UIImage(named: "wallpaper")!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(1.5)
                    .frame(width: 125, height: 50)
                    .cornerRadius(12)
                    .clipped()
                ZStack {
                    Text(exampleText)
                        .padding(.vertical, 5)
                        .foregroundColor(.white)
                }
                .frame(width: 125, height: 50)
            }
            .padding(.trailing, 5)
            Text(widgetName)
                .foregroundColor(.primary)
                .bold()
        }
    }
}

#Preview {
    WidgetCustomizationView()
}
