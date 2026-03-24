import SwiftUI

struct ContentView: View {
    @StateObject private var nfcWriter = NFCWriterSession()

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                // Company label
                Text("HOTBOT STUDIOS")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(3)
                    .foregroundColor(AppTheme.gold)

                Spacer().frame(height: 24)

                // Name
                Text("Harshpreet Singh")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(AppTheme.text)
                Text("Bhasin")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(AppTheme.text)

                Spacer().frame(height: 8)

                // Title
                Text("Managing Partner · CEO")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)

                Spacer().frame(height: 48)

                // NFC Button
                NFCButtonView(state: nfcWriter.writeState) {
                    nfcWriter.startWriteSession()
                }

                Spacer().frame(height: 32)

                // Status message
                statusView

                Spacer()

                // Info card
                if nfcWriter.isAvailable {
                    infoCard
                } else {
                    unavailableCard
                }

                Spacer().frame(height: 16)

                // Footer
                Text("harshpreetbhasin.com")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(1)
                    .foregroundColor(AppTheme.textMuted)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch nfcWriter.writeState {
        case .idle:
            Text("Place your iPhone on an NFC tag to write your business card")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        case .scanning:
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.accentLight))
                    .scaleEffect(0.8)
                Text("Hold steady on the tag...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.accentLight)
            }
        case .success:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 14))
                Text("Tag programmed successfully!")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.green)
            }
        case .error(let msg):
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
                Text(msg)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.orange)
            }
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("What this does", systemImage: "info.circle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.text)

            Text("Writes your full vCard and website URL to an NFC tag. Anyone who taps the tag with their phone will instantly see your digital business card and can save your contact.")
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(3)

            Divider().background(AppTheme.textMuted.opacity(0.3))

            HStack(spacing: 16) {
                Label("NTAG215+", systemImage: "tag")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(AppTheme.textMuted)
                Label("~350 bytes", systemImage: "internaldrive")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(AppTheme.textMuted)
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var unavailableCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "wave.3.right.circle")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.textMuted)

            Text("NFC Not Available")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.text)

            Text("This device does not support NFC tag writing. You need an iPhone 7 or later.")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(AppTheme.surface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
