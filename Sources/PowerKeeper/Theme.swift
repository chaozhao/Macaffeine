import SwiftUI

enum AppTheme {
    static let amber = Color(red: 1.0, green: 0.70, blue: 0.23)
    static let orange = Color(red: 0.94, green: 0.34, blue: 0.04)
    static let blue = Color(red: 0.22, green: 0.52, blue: 0.94)
    static let red = Color(red: 0.89, green: 0.26, blue: 0.20)
}

struct AppMark: View {
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.amber, AppTheme.orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: AppTheme.orange.opacity(0.25), radius: 4, x: 0, y: 2)
                .frame(width: size, height: size)

            Image(systemName: "power")
                .font(.system(size: size * 0.44, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}
