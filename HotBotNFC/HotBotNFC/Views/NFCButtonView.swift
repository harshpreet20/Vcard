import SwiftUI

struct NFCButtonView: View {
    let state: WriteState
    let action: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6
    @State private var successRotation: Double = 0

    var body: some View {
        ZStack {
            // Outer pulse rings
            if state == .idle || state == .scanning {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(AppTheme.accentLight.opacity(0.3), lineWidth: 2)
                        .frame(width: 192, height: 192)
                        .scaleEffect(pulseScale)
                        .opacity(pulseOpacity)
                        .animation(
                            .easeInOut(duration: state == .scanning ? 1.0 : 2.0)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.6),
                            value: pulseScale
                        )
                }
            }

            // Success ring
            if state == .success {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.green, AppTheme.gold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 188, height: 188)
                    .rotationEffect(.degrees(successRotation))
            }

            // Gradient ring border
            Circle()
                .stroke(AppTheme.ringGradient, lineWidth: 3)
                .frame(width: 180, height: 180)

            // Inner fill
            Circle()
                .fill(AppTheme.surface)
                .frame(width: 174, height: 174)

            // Button content
            Button(action: action) {
                VStack(spacing: 12) {
                    Group {
                        switch state {
                        case .idle:
                            Image(systemName: "wave.3.right")
                                .font(.system(size: 44, weight: .medium))
                                .foregroundColor(AppTheme.accentLight)
                        case .scanning:
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.accentLight))
                                .scaleEffect(1.6)
                        case .success:
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 44, weight: .medium))
                                .foregroundColor(.green)
                        case .error:
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 44, weight: .medium))
                                .foregroundColor(.orange)
                        }
                    }
                    .frame(height: 50)

                    Text(buttonLabel)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .frame(width: 174, height: 174)
            .disabled(state == .scanning)
        }
        .onAppear {
            pulseScale = 1.3
            pulseOpacity = 0
        }
        .onChange(of: state) { newState in
            if newState == .success {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    successRotation = 360
                }
            } else {
                successRotation = 0
            }
        }
    }

    private var buttonLabel: String {
        switch state {
        case .idle: return "TAP TO WRITE"
        case .scanning: return "SCANNING..."
        case .success: return "TAG WRITTEN!"
        case .error: return "TAP TO RETRY"
        }
    }
}
