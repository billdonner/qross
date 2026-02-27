import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // App icon
                    Image("LaunchImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .shadow(color: .purple.opacity(0.4), radius: 16)
                        .padding(.top, 20)

                    // Title
                    VStack(spacing: 6) {
                        Text("Qross")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("Navigate. Answer. Conquer.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Features
                    VStack(spacing: 0) {
                        featureRow("square.grid.3x3.fill", "Grid Navigation", "Move through a colorful trivia grid", .blue)
                        Divider().padding(.leading, 52)
                        featureRow("arrow.up.right.and.arrow.down.left.rectangle.fill", "Pick Your Corner", "Choose your start — opposite is the goal", .purple)
                        Divider().padding(.leading, 52)
                        featureRow("lightbulb.fill", "Smart Hints", "Show hint (+1) or eliminate a choice (+2)", .orange)
                        Divider().padding(.leading, 52)
                        featureRow("star.fill", "Score & Compete", "Game Center leaderboards and shareable results", .green)
                        Divider().padding(.leading, 52)
                        featureRow("eye.slash.fill", "3 Variants", "Face Up, Face Down, or Blind mode", .pink)
                        Divider().padding(.leading, 52)
                        featureRow("number", "20+ Topics", "Science, History, Pop Culture, and more", .cyan)
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Version
                    VStack(spacing: 4) {
                        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                            Text("Version \(version) (\(build))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("Built by Bill Donner and Claude Code")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Inspired by Carol Friedman")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("About Qross")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func featureRow(_ icon: String, _ title: String, _ subtitle: String, _ color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
