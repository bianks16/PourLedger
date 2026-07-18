//
//  ElementConfiguratorView.swift
//  PourLedger
//
//  Configure a single element and return its volume. Sheet. Spec §5.2.
//

import SwiftUI

struct CountStepper: View {
    @Binding var count: Int
    var range: ClosedRange<Int> = 1...999

    var body: some View {
        HStack(spacing: 0) {
            stepButton("minus") { if count > range.lowerBound { count -= 1; Haptics.selection() } }
            Text("×\(count)")
                .font(.plMetric(18, weight: .bold))
                .foregroundColor(Theme.textPrimary)
                .frame(minWidth: 58)
            stepButton("plus") { if count < range.upperBound { count += 1; Haptics.selection() } }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .castSurface(fill: Theme.surface)
    }

    private func stepButton(_ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .black))
                .foregroundColor(Theme.accent)
                .frame(width: 46, height: 34)
        }
        .buttonStyle(PressSink())
    }
}

struct ElementConfiguratorView: View {
    @Environment(\.dismiss) private var dismiss
    let editing: Bool
    @State var element: Element
    let onCommit: (Element) -> Void

    private var isColumn: Bool { element.type == .columnRect || element.type == .columnRound }

    private var typeSelection: Binding<ElementType> {
        Binding(
            get: { element.type == .columnRound ? .columnRect : element.type },
            set: { newType in
                guard newType != typeSelectionValue else { return }
                let old = element
                var e = Element.new(newType)
                e.id = old.id
                e.name = old.name
                e.count = old.count
                element = e
            }
        )
    }
    private var typeSelectionValue: ElementType {
        element.type == .columnRound ? .columnRect : element.type
    }

    var body: some View {
        SheetScaffold(title: editing ? "Edit element" : "New element",
                      subtitle: "Set the shape, drag or type the sizes",
                      onClose: { dismiss() }) {

            CastPanel(label: "Element type") {
                FormworkSegment(options: ElementType.pickerCases,
                                label: { $0.segmentLabel },
                                selection: typeSelection,
                                icon: { t in
                                    AnyView(SectionIcon(type: t == .columnRect ? .columnRect : t,
                                                        size: 24,
                                                        color: t == typeSelectionValue ? Theme.accentInk : Theme.textSecondary,
                                                        filled: false))
                                })

                if isColumn {
                    FormworkSegment(options: [ElementType.columnRect, ElementType.columnRound],
                                    label: { $0 == .columnRect ? "Rectangular" : "Round" },
                                    selection: Binding(
                                        get: { element.type },
                                        set: { element.type = $0 }
                                    ))
                        .padding(.top, 2)
                }

                TextField("Name (optional)", text: $element.name)
                    .font(.plBody(15))
                    .padding(11)
                    .castSurface(fill: Theme.surface)
            }

            CastPanel(label: "Dimensions") {
                dimInputs
                if isColumn || element.type == .beam {
                    HStack {
                        Text("COUNT").font(.plStamp(12)).tracking(0.6)
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                    }
                    CountStepper(count: $element.count)
                }
            }

            subtotalPanel

            HiVisButton(title: editing ? "Save element" : "Add to pour",
                        systemImage: editing ? "checkmark" : "plus",
                        kind: .solid,
                        enabled: element.isValid) {
                Haptics.rigid()
                onCommit(element)
                dismiss()
            }

            NoteLine(text: "Volume is computed live from these sizes and folded into the load gauge.")
        }
    }

    @ViewBuilder private var dimInputs: some View {
        switch element.type {
        case .slab:
            DimInput(title: "Length", meters: $element.dims.l, unit: .m,
                     displayRange: 0...40, ticksStep: 0.1, majorEvery: 10, decimals: 2)
            DimInput(title: "Width", meters: $element.dims.w, unit: .m,
                     displayRange: 0...40, ticksStep: 0.1, majorEvery: 10, decimals: 2)
            DimInput(title: "Thickness", meters: $element.dims.t, unit: .mm,
                     displayRange: 0...600, ticksStep: 5, majorEvery: 10, decimals: 0)
        case .strip:
            DimInput(title: "Run length", meters: $element.dims.l, unit: .m,
                     displayRange: 0...300, ticksStep: 0.1, majorEvery: 10, decimals: 2)
            DimInput(title: "Width", meters: $element.dims.w, unit: .mm,
                     displayRange: 0...1200, ticksStep: 10, majorEvery: 10, decimals: 0)
            DimInput(title: "Depth", meters: $element.dims.d, unit: .mm,
                     displayRange: 0...1500, ticksStep: 10, majorEvery: 10, decimals: 0)
        case .columnRect:
            DimInput(title: "Section A", meters: $element.dims.sectionA, unit: .mm,
                     displayRange: 0...1500, ticksStep: 10, majorEvery: 10, decimals: 0)
            DimInput(title: "Section B", meters: $element.dims.sectionB, unit: .mm,
                     displayRange: 0...1500, ticksStep: 10, majorEvery: 10, decimals: 0)
            DimInput(title: "Height", meters: $element.dims.h, unit: .m,
                     displayRange: 0...15, ticksStep: 0.1, majorEvery: 10, decimals: 2)
        case .columnRound:
            DimInput(title: "Diameter", meters: $element.dims.diameter, unit: .mm,
                     displayRange: 0...1800, ticksStep: 10, majorEvery: 10, decimals: 0)
            DimInput(title: "Height", meters: $element.dims.h, unit: .m,
                     displayRange: 0...15, ticksStep: 0.1, majorEvery: 10, decimals: 2)
        case .beam:
            DimInput(title: "Width (b)", meters: $element.dims.sectionA, unit: .mm,
                     displayRange: 0...1200, ticksStep: 10, majorEvery: 10, decimals: 0)
            DimInput(title: "Height (h)", meters: $element.dims.sectionB, unit: .mm,
                     displayRange: 0...1500, ticksStep: 10, majorEvery: 10, decimals: 0)
            DimInput(title: "Length", meters: $element.dims.length, unit: .m,
                     displayRange: 0...30, ticksStep: 0.1, majorEvery: 10, decimals: 2)
        case .custom:
            DimInput(title: "Length", meters: $element.dims.l, unit: .m,
                     displayRange: 0...40, ticksStep: 0.1, majorEvery: 10, decimals: 2)
            DimInput(title: "Width", meters: $element.dims.w, unit: .m,
                     displayRange: 0...40, ticksStep: 0.1, majorEvery: 10, decimals: 2)
            DimInput(title: "Depth", meters: $element.dims.d, unit: .m,
                     displayRange: 0...10, ticksStep: 0.05, majorEvery: 10, decimals: 2)
        }
    }

    private var subtotalPanel: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SUBTOTAL").font(.plStamp(12)).tracking(0.8)
                    .foregroundColor(Theme.textSecondary)
                if !element.isValid {
                    Text("check dimensions").font(.plCaption(12))
                        .foregroundColor(Theme.short)
                }
            }
            Spacer()
            MonoDisplay(value: Fmt.vol2(element.volume), unit: "m³", size: 40,
                        color: element.isValid ? Theme.accent : Theme.textSecondary)
        }
        .padding(16)
        .castSurface(fill: Theme.surfaceElevated)
    }
}
