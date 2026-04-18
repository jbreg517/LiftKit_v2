import SwiftUI

struct TimerDisplayView: View {
    let timeString: String
    var color: Color = LKColors.Hex.textPrimary
    var size: CGFloat = 112

    var body: some View {
        Text(timeString)
            .font(LKFont.timer(size))
            .foregroundStyle(color)
            .minimumScaleFactor(0.5)
            .contentTransition(.numericText())
            .monospacedDigit()
    }
}
