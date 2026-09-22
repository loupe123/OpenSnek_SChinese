import OpenSnekCore
import SwiftUI

/// Anchor geometry that maps Razer button slot ids onto normalized points inside the mouse chassis.
///
/// The points follow the Basilisk V3 product photography: the chunky right-handed body, the tall
/// lit scroll wheel with its tilt arrows, the two controls behind the wheel, the protruding
/// multi-function trigger and the thumb cluster on the left flank.
enum MouseMapAnchor {
    /// Normalized (`0...1`) anchor inside the chassis rect, or `nil` when the slot has no dedicated anchor.
    static func normalizedPoint(for slot: Int) -> CGPoint? {
        switch slot {
        case 1: return CGPoint(x: 0.315, y: 0.190)
        case 2: return CGPoint(x: 0.685, y: 0.190)
        case 9: return CGPoint(x: 0.500, y: 0.165)
        case 3: return CGPoint(x: 0.500, y: 0.205)
        case 10: return CGPoint(x: 0.500, y: 0.280)
        case 52: return CGPoint(x: 0.415, y: 0.222)
        case 53: return CGPoint(x: 0.585, y: 0.222)
        // Behind the wheel sit two separate controls: the scroll-mode toggle and the DPI cycle button.
        case 14: return CGPoint(x: 0.445, y: 0.338)
        case 96: return CGPoint(x: 0.555, y: 0.338)
        // Left flank, front to back: multi-function trigger, clutch paddle, then the thumb buttons.
        case 6: return CGPoint(x: 0.125, y: 0.268)
        case 15: return CGPoint(x: 0.148, y: 0.420)
        case 4: return CGPoint(x: 0.140, y: 0.512)
        case 5: return CGPoint(x: 0.140, y: 0.596)
        case 106: return CGPoint(x: 0.500, y: 0.880)
        default: return nil
        }
    }

    /// Slots without a dedicated anchor stack along the lower left flank so exotic layouts still get a call-out.
    static func fallbackPoint(index: Int) -> CGPoint { CGPoint(x: 0.070, y: 0.70 + (Double(index) * 0.055)) }
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

    private let chassisSize = CGSize(width: 216, height: 340)
    private let verticalInset: CGFloat = 12
    /// Gap between the chassis flank and the call-out label, so the leader elbow has room to read.
    private let labelGap: CGFloat = 26
    /// Minimum vertical distance between two labels on the same flank.
    private let minimumLabelSpacing: CGFloat = 30

    var body: some View {
        GeometryReader { proxy in
            let chassis = CGRect(x: (proxy.size.width - chassisSize.width) / 2, y: (proxy.size.height - chassisSize.height) / 2, width: chassisSize.width, height: chassisSize.height)
            let leftCallouts = callouts(side: .left)
            let rightCallouts = callouts(side: .right)
            let labelWidth = max((proxy.size.width - chassisSize.width) / 2 - labelGap - 8, 72)
            let leftLabels = labelPositions(callouts: leftCallouts, chassis: chassis, height: proxy.size.height)
            let rightLabels = labelPositions(callouts: rightCallouts, chassis: chassis, height: proxy.size.height)

            ZStack(alignment: .topLeading) {
                MouseChassisView().frame(width: chassisSize.width, height: chassisSize.height).position(x: chassis.midX, y: chassis.midY)

                leaderPath(callouts: leftCallouts, labelYs: leftLabels, chassis: chassis, side: .left).stroke(Color.white.opacity(0.30), style: StrokeStyle(lineWidth: 1, lineCap: .round)).allowsHitTesting(false)

                leaderPath(callouts: rightCallouts, labelYs: rightLabels, chassis: chassis, side: .right).stroke(Color.white.opacity(0.30), style: StrokeStyle(lineWidth: 1, lineCap: .round)).allowsHitTesting(false)

                ForEach(Array(leftCallouts.enumerated()), id: \.element.id) { index, callout in labelView(callout, width: labelWidth).position(x: chassis.minX - labelGap - (labelWidth / 2), y: leftLabels[index]) }

                ForEach(Array(rightCallouts.enumerated()), id: \.element.id) { index, callout in labelView(callout, width: labelWidth).position(x: chassis.maxX + labelGap + (labelWidth / 2), y: rightLabels[index]) }
            }.frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    /// Places each label at its own anchor height, then relaxes overlaps down the flank.
    ///
    /// Anchoring labels to their target's height is what keeps leader lines from crossing: each line
    /// stays close to horizontal instead of sweeping across the diagram.
    private func labelPositions(callouts: [MouseMapCallout], chassis: CGRect, height: CGFloat) -> [CGFloat] {
        var positions: [CGFloat] = []
        var previous = -CGFloat.greatestFiniteMagnitude
        for callout in callouts {
            let desired = chassis.minY + (callout.anchor.y * chassis.height)
            let clamped = min(max(desired, verticalInset), height - verticalInset)
            let y = max(clamped, previous + minimumLabelSpacing)
            positions.append(y)
            previous = y
        }
        if let last = positions.last, last > height - verticalInset {
            let overflow = last - (height - verticalInset)
            positions = positions.map { $0 - overflow }
        }
        return positions
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

    /// Draws the official-style elbow leader: a horizontal stub out of the label, then a run into the button.
    private func leaderPath(callouts: [MouseMapCallout], labelYs: [CGFloat], chassis: CGRect, side: MouseMapCallout.Side) -> Path {
        var path = Path()
        for (index, callout) in callouts.enumerated() {
            guard index < labelYs.count else { continue }
            let y = labelYs[index]
            let anchor = CGPoint(x: chassis.minX + (callout.anchor.x * chassis.width), y: chassis.minY + (callout.anchor.y * chassis.height))
            let labelEdgeX: CGFloat = side == .left ? chassis.minX - labelGap : chassis.maxX + labelGap
            let stubX: CGFloat = side == .left ? labelEdgeX - 10 : labelEdgeX + 10

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

/// Renders the stylized top-down Basilisk V3 chassis with its grips, wheel and button seams.
private struct MouseChassisView: View {
    private let accent = Color(hex: 0x44D62C)
    private let seam = Color.white.opacity(0.20)
    private let controlFill = Color.white.opacity(0.16)
    private let controlStroke = Color.white.opacity(0.32)

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                // Body with the chunky shoulders, bulging grip flanks and rounded heel.
                MouseChassisShape().fill(LinearGradient(colors: [Color.white.opacity(0.30), Color.white.opacity(0.12)], startPoint: .top, endPoint: .bottom)).overlay(MouseChassisShape().stroke(Color.white.opacity(0.52), lineWidth: 1.3))

                hexGripPanel(width: width, height: height, mirrored: false)
                hexGripPanel(width: width, height: height, mirrored: true)

                // Main button seams running out of the wheel housing to each shoulder.
                Path { path in
                    path.move(to: CGPoint(x: width * 0.50, y: height * 0.315))
                    path.addLine(to: CGPoint(x: width * 0.50, y: height * 0.020))
                    path.move(to: CGPoint(x: width * 0.185, y: height * 0.300))
                    path.addQuadCurve(to: CGPoint(x: width * 0.50, y: height * 0.300), control: CGPoint(x: width * 0.35, y: height * 0.360))
                    path.move(to: CGPoint(x: width * 0.815, y: height * 0.300))
                    path.addQuadCurve(to: CGPoint(x: width * 0.50, y: height * 0.300), control: CGPoint(x: width * 0.65, y: height * 0.360))
                }.stroke(seam, lineWidth: 1)

                // The angled centre panel leading down to the logo.
                Path { path in
                    path.move(to: CGPoint(x: width * 0.335, y: height * 0.395))
                    path.addLine(to: CGPoint(x: width * 0.665, y: height * 0.395))
                    path.addLine(to: CGPoint(x: width * 0.610, y: height * 0.780))
                    path.addLine(to: CGPoint(x: width * 0.390, y: height * 0.780))
                    path.closeSubpath()
                }.stroke(Color.white.opacity(0.13), lineWidth: 1)

                scrollWheel(width: width, height: height)

                // Wheel tilt arrows painted either side of the housing.
                Text("<").font(.system(size: 8, weight: .black)).foregroundStyle(Color.white.opacity(0.55)).position(x: width * 0.415, y: height * 0.222)
                Text(">").font(.system(size: 8, weight: .black)).foregroundStyle(Color.white.opacity(0.55)).position(x: width * 0.585, y: height * 0.222)

                // Two controls behind the wheel: scroll-mode toggle (left) and DPI cycle (right).
                RoundedRectangle(cornerRadius: 3).fill(controlFill).overlay(RoundedRectangle(cornerRadius: 3).stroke(controlStroke, lineWidth: 1)).frame(width: width * 0.095, height: height * 0.026).position(x: width * 0.445, y: height * 0.338)

                RoundedRectangle(cornerRadius: 3).fill(controlFill).overlay(RoundedRectangle(cornerRadius: 3).stroke(controlStroke, lineWidth: 1)).frame(width: width * 0.078, height: height * 0.026).position(x: width * 0.555, y: height * 0.338)

                // Multi-function trigger protruding from the front left flank.
                Capsule().fill(controlFill).overlay(Capsule().stroke(controlStroke, lineWidth: 1)).frame(width: width * 0.150, height: height * 0.052).rotationEffect(.degrees(-8)).position(x: width * 0.128, y: height * 0.268)

                // Clutch paddle, then the two thumb buttons further back.
                Capsule().fill(Color.white.opacity(0.13)).overlay(Capsule().stroke(Color.white.opacity(0.28), lineWidth: 1)).frame(width: width * 0.085, height: height * 0.058).position(x: width * 0.150, y: height * 0.420)

                ForEach([0.512, 0.596], id: \.self) { thumbY in Capsule().fill(controlFill).overlay(Capsule().stroke(controlStroke, lineWidth: 1)).frame(width: width * 0.085, height: height * 0.056).position(x: width * 0.142, y: height * thumbY) }

                // Underside profile button.
                Capsule().fill(Color.white.opacity(0.10)).overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 1)).frame(width: width * 0.100, height: height * 0.020).position(x: width * 0.5, y: height * 0.880)

                triSnakeMark(width: width, height: height)
            }
        }
    }

    /// Tall ribbed wheel with the signature accent glow and highlight ribs.
    private func scrollWheel(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.60)).overlay(RoundedRectangle(cornerRadius: 6).stroke(accent.opacity(0.90), lineWidth: 1.5)).frame(width: width * 0.115, height: height * 0.185)

            ForEach(0..<5, id: \.self) { index in RoundedRectangle(cornerRadius: 1).fill(accent.opacity(0.55)).frame(width: width * 0.070, height: 1.2).position(x: width * 0.5, y: height * (0.105 + (Double(index) * 0.032))) }
        }
    }

    /// Hexagonal rubber grip flank, suggested with a rounded panel and a short hatch run.
    private func hexGripPanel(width: CGFloat, height: CGFloat, mirrored: Bool) -> some View {
        let centreX = mirrored ? width * 0.870 : width * 0.130
        let rotation: Double = mirrored ? 10 : -10
        return ZStack {
            RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.24)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.16), lineWidth: 1)).frame(width: width * 0.215, height: height * 0.300)

            ForEach(0..<7, id: \.self) { index in Capsule().fill(Color.white.opacity(0.10)).frame(width: width * 0.150, height: 1).position(x: width * 0.5, y: height * (0.355 + (Double(index) * 0.036))) }
        }.frame(width: width * 0.215, height: height * 0.300).rotationEffect(.degrees(rotation)).position(x: centreX, y: height * 0.475)
    }

    /// Three stylized stroke fan standing in for the moulded logo on the palm rest.
    private func triSnakeMark(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: width * 0.500, y: height * 0.805))
            path.addQuadCurve(to: CGPoint(x: width * 0.360, y: height * 0.878), control: CGPoint(x: width * 0.385, y: height * 0.812))
            path.move(to: CGPoint(x: width * 0.500, y: height * 0.805))
            path.addQuadCurve(to: CGPoint(x: width * 0.500, y: height * 0.888), control: CGPoint(x: width * 0.472, y: height * 0.848))
            path.move(to: CGPoint(x: width * 0.500, y: height * 0.805))
            path.addQuadCurve(to: CGPoint(x: width * 0.640, y: height * 0.878), control: CGPoint(x: width * 0.615, y: height * 0.812))
        }.stroke(accent.opacity(0.75), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
    }
}

/// Top-down Basilisk V3 silhouette: chunky shoulders, bulging grip flanks, rounded heel.
private struct MouseChassisShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        var path = Path()
        path.move(to: CGPoint(x: width * 0.50, y: height * 1.00))
        path.addCurve(to: CGPoint(x: width * 0.940, y: height * 0.440), control1: CGPoint(x: width * 0.870, y: height * 0.992), control2: CGPoint(x: width * 0.940, y: height * 0.720))
        path.addCurve(to: CGPoint(x: width * 0.905, y: height * 0.170), control1: CGPoint(x: width * 0.940, y: height * 0.300), control2: CGPoint(x: width * 0.940, y: height * 0.225))
        path.addCurve(to: CGPoint(x: width * 0.565, y: height * 0.020), control1: CGPoint(x: width * 0.865, y: height * 0.095), control2: CGPoint(x: width * 0.715, y: height * 0.020))
        path.addCurve(to: CGPoint(x: width * 0.435, y: height * 0.020), control1: CGPoint(x: width * 0.530, y: height * 0.020), control2: CGPoint(x: width * 0.470, y: height * 0.020))
        path.addCurve(to: CGPoint(x: width * 0.095, y: height * 0.170), control1: CGPoint(x: width * 0.285, y: height * 0.020), control2: CGPoint(x: width * 0.135, y: height * 0.095))
        path.addCurve(to: CGPoint(x: width * 0.060, y: height * 0.440), control1: CGPoint(x: width * 0.060, y: height * 0.225), control2: CGPoint(x: width * 0.060, y: height * 0.300))
        path.addCurve(to: CGPoint(x: width * 0.50, y: height * 1.00), control1: CGPoint(x: width * 0.130, y: height * 0.720), control2: CGPoint(x: width * 0.245, y: height * 0.992))
        path.closeSubpath()
        return path
    }
}
