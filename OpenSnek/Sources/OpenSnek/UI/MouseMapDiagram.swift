import OpenSnekCore
import SwiftUI

/// Anchor geometry that maps Razer button slot ids onto normalized points inside the mouse chassis.
enum MouseMapAnchor {
    /// Normalized (`0...1`) anchor inside the chassis rect, or `nil` when the slot has no dedicated anchor.
    static func normalizedPoint(for slot: Int) -> CGPoint? {
        switch slot {
        case 1: return CGPoint(x: 0.325, y: 0.098)
        case 2: return CGPoint(x: 0.675, y: 0.098)
        case 3: return CGPoint(x: 0.50, y: 0.140)
        case 9: return CGPoint(x: 0.50, y: 0.070)
        case 10: return CGPoint(x: 0.50, y: 0.212)
        case 52: return CGPoint(x: 0.435, y: 0.172)
        case 53: return CGPoint(x: 0.565, y: 0.172)
        // Basilisk V3 carries two controls behind the wheel: the scroll-mode toggle and the DPI cycle button.
        case 14: return CGPoint(x: 0.435, y: 0.290)
        case 96: return CGPoint(x: 0.565, y: 0.290)
        case 15: return CGPoint(x: 0.140, y: 0.470)
        case 6: return CGPoint(x: 0.110, y: 0.360)
        case 4: return CGPoint(x: 0.105, y: 0.585)
        case 5: return CGPoint(x: 0.105, y: 0.672)
        case 106: return CGPoint(x: 0.50, y: 0.860)
        default: return nil
        }
    }

    /// Slots without a dedicated anchor stack along the lower left flank so exotic layouts still get a call-out.
    static func fallbackPoint(index: Int) -> CGPoint { CGPoint(x: 0.075, y: 0.78 + (Double(index) * 0.052)) }
}

/// A single call-out label attached to a mouse button.
private struct MouseMapCallout: Identifiable {
    /// Which flank of the chassis the call-out label lives on.
    enum Side {
        case left
        case right
    }

    let slot: Int
    let title: String
    let action: String
    let side: Side
    let anchor: CGPoint

    var id: Int { slot }
}

/// Renders the official-style top-down mouse map with leader lines to each button.
struct MouseMapDiagram: View {
    let rows: [ButtonBindingRowModel]
    let selectedSlot: Int?
    let onSelect: (Int) -> Void

    private let chassisSize = CGSize(width: 196, height: 336)
    private let verticalInset: CGFloat = 14
    /// Gap between the chassis flank and the call-out label, so the leader elbow has room to read.
    private let labelGap: CGFloat = 30

    var body: some View {
        GeometryReader { proxy in
            let chassis = CGRect(x: (proxy.size.width - chassisSize.width) / 2, y: (proxy.size.height - chassisSize.height) / 2, width: chassisSize.width, height: chassisSize.height)
            let leftCallouts = callouts(side: .left)
            let rightCallouts = callouts(side: .right)
            let labelWidth = max((proxy.size.width - chassisSize.width) / 2 - labelGap - 6, 76)

            ZStack(alignment: .topLeading) {
                MouseChassisView().frame(width: chassisSize.width, height: chassisSize.height).position(x: chassis.midX, y: chassis.midY)

                leaderPath(callouts: leftCallouts, chassis: chassis, height: proxy.size.height, side: .left).stroke(Color.white.opacity(0.30), style: StrokeStyle(lineWidth: 1, lineCap: .round)).allowsHitTesting(false)

                leaderPath(callouts: rightCallouts, chassis: chassis, height: proxy.size.height, side: .right).stroke(Color.white.opacity(0.30), style: StrokeStyle(lineWidth: 1, lineCap: .round)).allowsHitTesting(false)

                ForEach(Array(leftCallouts.enumerated()), id: \.element.id) { index, callout in labelView(callout, width: labelWidth).position(x: chassis.minX - labelGap - (labelWidth / 2), y: labelY(index: index, count: leftCallouts.count, height: proxy.size.height)) }

                ForEach(Array(rightCallouts.enumerated()), id: \.element.id) { index, callout in labelView(callout, width: labelWidth).position(x: chassis.maxX + labelGap + (labelWidth / 2), y: labelY(index: index, count: rightCallouts.count, height: proxy.size.height)) }
            }.frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private func labelY(index: Int, count: Int, height: CGFloat) -> CGFloat {
        guard count > 1 else { return height / 2 }
        let usable = max(height - (verticalInset * 2), 1)
        return verticalInset + (usable * CGFloat(index) / CGFloat(count - 1))
    }

    private func labelView(_ callout: MouseMapCallout, width: CGFloat) -> some View {
        let isSelected = callout.slot == selectedSlot
        let alignment: HorizontalAlignment = callout.side == .left ? .trailing : .leading
        return Button {
            onSelect(callout.slot)
        } label: {
            VStack(alignment: alignment, spacing: 2) {
                Text(LocalizedStringKey(callout.title)).font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(isSelected ? Color(hex: 0x44D62C) : Color.white.opacity(0.88)).lineLimit(1)
                Text(LocalizedStringKey(callout.action)).font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(isSelected ? Color(hex: 0x44D62C).opacity(0.78) : Color.white.opacity(0.48)).lineLimit(1)
            }.frame(width: width, alignment: callout.side == .left ? .trailing : .leading).padding(.vertical, 3).padding(.horizontal, 6).background(
                RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(isSelected ? 0.10 : 0.02)).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(isSelected ? 0.32 : 0.10), lineWidth: 1))
            ).contentShape(RoundedRectangle(cornerRadius: 8))
        }.buttonStyle(.plain).accessibilityIdentifier("mouse-map-callout-\(callout.slot)")
    }

    /// Draws the official-style elbow leader: a horizontal stub out of the label, then a diagonal into the button.
    private func leaderPath(callouts: [MouseMapCallout], chassis: CGRect, height: CGFloat, side: MouseMapCallout.Side) -> Path {
        var path = Path()
        for (index, callout) in callouts.enumerated() {
            let y = labelY(index: index, count: callouts.count, height: height)
            let anchor = CGPoint(x: chassis.minX + (callout.anchor.x * chassis.width), y: chassis.minY + (callout.anchor.y * chassis.height))
            let labelEdgeX: CGFloat = side == .left ? chassis.minX - labelGap : chassis.maxX + labelGap
            let stubX: CGFloat = side == .left ? labelEdgeX - 8 : labelEdgeX + 8

            path.move(to: CGPoint(x: labelEdgeX, y: y))
            path.addLine(to: CGPoint(x: stubX, y: y))
            path.addLine(to: anchor)
        }
        return path
    }

    private func callouts(side: MouseMapCallout.Side) -> [MouseMapCallout] {
        var fallbackIndex = 0
        var result: [MouseMapCallout] = []
        for row in rows {
            let anchor: CGPoint
            if let dedicated = MouseMapAnchor.normalizedPoint(for: row.slot) {
                anchor = dedicated
            } else {
                anchor = MouseMapAnchor.fallbackPoint(index: fallbackIndex)
                fallbackIndex += 1
            }
            let calloutSide: MouseMapCallout.Side = anchor.x < 0.5 ? .left : .right
            guard calloutSide == side else { continue }
            result.append(MouseMapCallout(slot: row.slot, title: row.friendlyName, action: row.actionLabel, side: side, anchor: anchor))
        }
        // Ordering by anchor height keeps leader lines from crossing each other on the same flank.
        return result.sorted { $0.anchor.y < $1.anchor.y }
    }
}

/// Renders the stylized top-down mouse chassis with its wheel, button seams and side buttons.
private struct MouseChassisView: View {
    private let bodyFill = LinearGradient(colors: [Color.white.opacity(0.30), Color.white.opacity(0.10)], startPoint: .top, endPoint: .bottom)
    private let accent = Color(hex: 0x44D62C)

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let width = size.width
            let height = size.height

            ZStack {
                MouseChassisShape().fill(bodyFill).overlay(MouseChassisShape().stroke(Color.white.opacity(0.52), lineWidth: 1.4))

                // Button seams: the left/right main button split running out of the wheel housing.
                Path { path in
                    path.move(to: CGPoint(x: width * 0.5, y: height * 0.245))
                    path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.02))
                }.stroke(Color.white.opacity(0.22), lineWidth: 1)

                Path { path in
                    path.move(to: CGPoint(x: width * 0.115, y: height * 0.245))
                    path.addQuadCurve(to: CGPoint(x: width * 0.5, y: height * 0.215), control: CGPoint(x: width * 0.30, y: height * 0.30))
                    path.move(to: CGPoint(x: width * 0.885, y: height * 0.245))
                    path.addQuadCurve(to: CGPoint(x: width * 0.5, y: height * 0.215), control: CGPoint(x: width * 0.70, y: height * 0.30))
                }.stroke(Color.white.opacity(0.18), lineWidth: 1)

                // Scroll wheel with the signature accent glow.
                RoundedRectangle(cornerRadius: 7).fill(Color.black.opacity(0.55)).overlay(RoundedRectangle(cornerRadius: 7).stroke(accent.opacity(0.85), lineWidth: 1.4)).frame(width: width * 0.15, height: height * 0.155).position(x: width * 0.5, y: height * 0.145)

                ForEach(0..<4, id: \.self) { index in RoundedRectangle(cornerRadius: 1).fill(accent.opacity(0.45)).frame(width: width * 0.09, height: 1.2).position(x: width * 0.5, y: height * (0.105 + (Double(index) * 0.026))) }

                // Back / forward thumb buttons, sitting below the sensitivity clutch paddle.
                ForEach([0.585, 0.672], id: \.self) { thumbY in Capsule().fill(Color.white.opacity(0.16)).overlay(Capsule().stroke(Color.white.opacity(0.30), lineWidth: 1)).frame(width: width * 0.09, height: height * 0.072).position(x: width * 0.128, y: height * thumbY) }

                Capsule().fill(Color.white.opacity(0.13)).overlay(Capsule().stroke(Color.white.opacity(0.26), lineWidth: 1)).frame(width: width * 0.08, height: height * 0.066).position(x: width * 0.170, y: height * 0.470)

                // The two controls behind the wheel: scroll-mode toggle on the left, DPI cycle on the right.
                RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.16)).overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.white.opacity(0.30), lineWidth: 1)).frame(width: width * 0.105, height: height * 0.024).position(x: width * 0.435, y: height * 0.290)

                RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.16)).overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.white.opacity(0.30), lineWidth: 1)).frame(width: width * 0.105, height: height * 0.024).position(x: width * 0.565, y: height * 0.290)

                // Underside profile button.
                Capsule().fill(Color.white.opacity(0.10)).overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 1)).frame(width: width * 0.10, height: height * 0.020).position(x: width * 0.5, y: height * 0.860)
            }
        }
    }
}

/// Top-down mouse silhouette: wide rounded shoulders tapering into a rounded heel.
private struct MouseChassisShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        var path = Path()
        path.move(to: CGPoint(x: width * 0.50, y: height))
        path.addCurve(to: CGPoint(x: width * 0.99, y: height * 0.40), control1: CGPoint(x: width * 0.88, y: height * 0.99), control2: CGPoint(x: width * 0.99, y: height * 0.70))
        path.addCurve(to: CGPoint(x: width * 0.52, y: 0), control1: CGPoint(x: width * 0.99, y: height * 0.12), control2: CGPoint(x: width * 0.78, y: 0))
        path.addCurve(to: CGPoint(x: width * 0.015, y: height * 0.40), control1: CGPoint(x: width * 0.26, y: 0), control2: CGPoint(x: width * 0.015, y: height * 0.12))
        // Right-handed ergonomics: the left flank bulges into a thumb rest before tapering to the heel.
        path.addCurve(to: CGPoint(x: width * 0.055, y: height * 0.72), control1: CGPoint(x: width * -0.035, y: height * 0.54), control2: CGPoint(x: width * -0.015, y: height * 0.68))
        path.addCurve(to: CGPoint(x: width * 0.50, y: height), control1: CGPoint(x: width * 0.19, y: height * 0.92), control2: CGPoint(x: width * 0.30, y: height))
        path.closeSubpath()
        return path
    }
}
