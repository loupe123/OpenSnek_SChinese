import OpenSnekCore
import SwiftUI

/// Renders the button mapping page: an official-style mouse map on the left and the full mapping list on the right.
struct ButtonMappingPage: View {
    let deviceStore: DeviceStore
    let editorStore: EditorStore

    @State private var selectedSlot: Int?

    private var isBusy: Bool { editorStore.isButtonProfileOperationInFlight || editorStore.isOnboardProfileLoadInFlight }

    private var rows: [ButtonBindingRowModel] { buttonBindingRowModels(deviceStore: deviceStore, editorStore: editorStore, isBusy: isBusy) }

    private var selectedRow: ButtonBindingRowModel? { selectedSlot.flatMap { slot in rows.first { $0.slot == slot } } }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            mapPanel

            ButtonMappingTableCard(deviceStore: deviceStore, editorStore: editorStore, title: "Buttons").frame(maxWidth: 560)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mapPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Click a button on the mouse to edit it.").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.58)).frame(maxWidth: .infinity, alignment: .leading)

            MouseMapDiagram(rows: rows, selectedSlot: selectedSlot, onSelect: toggleSelection).frame(minHeight: 440).accessibilityIdentifier("mouse-map-diagram")

            if let selectedRow { selectedEditor(selectedRow) }
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.07)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18), lineWidth: 1))).contentShape(RoundedRectangle(cornerRadius: 14))
    }

    private func toggleSelection(_ slot: Int) { selectedSlot = selectedSlot == slot ? nil : slot }

    @ViewBuilder private func selectedEditor(_ row: ButtonBindingRowModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected button").font(.system(size: 10, weight: .black, design: .rounded)).foregroundStyle(.white.opacity(0.42)).textCase(.uppercase).tracking(0.6)

            ButtonBindingRow(editorStore: editorStore, row: row)
        }.frame(maxWidth: .infinity, alignment: .leading).transition(.opacity)
    }
}
