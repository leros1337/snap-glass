import SnapGlassCore
import SwiftUI

struct PreferencesView: View {
    @ObservedObject var model: PreferencesModel
    @ObservedObject private var coordinator: ShortcutCoordinator
    @State private var isResetConfirmationPresented = false

    private let keys = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

    init(model: PreferencesModel) {
        self.model = model
        self.coordinator = model.coordinator
    }

    var body: some View {
        ZStack {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.55], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    Color(red: 0.17, green: 0.21, blue: 0.24), Color(red: 0.34, green: 0.39, blue: 0.38), Color(red: 0.18, green: 0.19, blue: 0.28),
                    Color(red: 0.23, green: 0.31, blue: 0.30), Color(red: 0.58, green: 0.61, blue: 0.58), Color(red: 0.32, green: 0.27, blue: 0.30),
                    Color(red: 0.13, green: 0.15, blue: 0.16), Color(red: 0.28, green: 0.36, blue: 0.35), Color(red: 0.43, green: 0.35, blue: 0.25)
                ]
            )
            .ignoresSafeArea()
            .overlay(.black.opacity(0.16))

            VStack(alignment: .leading, spacing: 18) {
                header
                appSettings
                shortcutControls
                shortcutLists
            }
            .padding(28)
        }
        .frame(minWidth: 680, minHeight: 460)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 58, height: 58)
                .glassPanel(cornerRadius: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text("SnapGlass")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white.opacity(0.94))
            }

            Spacer()

            HStack(spacing: 10) {
                Text("Dock modifier")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.86))
                    .fixedSize()

                Picker("Dock modifier", selection: $coordinator.automaticModifier) {
                    ForEach(ShortcutModifier.allCases) { modifier in
                        Text(modifier.displayName)
                            .foregroundStyle(.white)
                            .tag(modifier)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 300)
            }
        }
    }

    private var appSettings: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsToggleRow(
                title: "Launch at system start",
                systemImage: "power",
                isOn: $model.launchAtLogin
            )

            settingsToggleRow(
                title: "Show menu bar icon",
                systemImage: "menubar.rectangle",
                isOn: $model.showStatusIcon
            )

            Divider()
                .opacity(0.45)

            Button(role: .destructive) {
                isResetConfirmationPresented = true
            } label: {
                Label("Restore defaults", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .confirmationDialog(
                "Restore default settings?",
                isPresented: $isResetConfirmationPresented
            ) {
                Button("Restore Defaults", role: .destructive) {
                    model.restoreDefaults()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes all manual shortcuts and resets launch, Dock modifier, and menu bar icon settings.")
            }

            if let settingsError = model.settingsError {
                Text(settingsError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
        .toggleStyle(.switch)
        .padding(14)
        .glassPanel(cornerRadius: 18)
    }

    private func settingsToggleRow(
        title: String,
        systemImage: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            Label(title, systemImage: systemImage)
                .frame(width: 230, alignment: .leading)
                .lineLimit(1)

            Toggle(title, isOn: isOn)
                .labelsHidden()
                .frame(width: 52, alignment: .trailing)
        }
    }

    private var shortcutControls: some View {
        HStack(spacing: 12) {
            Picker("Application", selection: $model.selectedApp) {
                Text("Choose app").tag(AppRecord?.none)
                ForEach(model.installedApps) { app in
                    Text(app.name).tag(Optional(app))
                }
            }
            .frame(minWidth: 260)

            Picker("Modifier", selection: $model.selectedModifier) {
                ForEach(ShortcutModifier.allCases) { modifier in
                    Text(modifier.symbol).tag(modifier)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)

            Picker("Key", selection: $model.selectedKey) {
                ForEach(keys, id: \.self) { key in
                    Text(key).tag(key)
                }
            }
            .frame(width: 88)

            Button {
                model.addSelectedShortcut()
            } label: {
                Image(systemName: "plus")
            }
            .help("Add manual shortcut")
        }
        .padding(14)
        .glassPanel(cornerRadius: 18)
    }

    private var shortcutLists: some View {
        HStack(alignment: .top, spacing: 16) {
            assignmentList(title: "Dock", assignments: coordinator.dockAssignments)

            VStack(alignment: .leading, spacing: 10) {
                Text("Manual")
                    .font(.headline)
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(coordinator.manualShortcuts) { shortcut in
                            HStack {
                                Text(shortcut.app.name)
                                Spacer()
                                Text("\(shortcut.modifier.symbol)\(shortcut.key)")
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                    .monospaced()
                                Button(role: .destructive) {
                                    coordinator.removeManualShortcut(shortcut)
                                } label: {
                                    Image(systemName: "trash")
                                        .frame(width: 18, height: 18)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .help("Remove manual shortcut")
                            }
                            .padding(10)
                            .glassPanel(cornerRadius: 12)
                        }
                    }
                }
            }
            .padding(14)
            .glassPanel(cornerRadius: 18)
        }
    }

    private func assignmentList(title: String, assignments: [ShortcutAssignment]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(assignments) { assignment in
                        HStack {
                            Text(assignment.displayShortcut)
                                .font(.system(.body, design: .rounded).weight(.bold))
                                .frame(width: 46, alignment: .leading)
                            Text(assignment.app.name)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(10)
                        .glassPanel(cornerRadius: 12)
                    }
                }
            }
        }
        .padding(14)
        .glassPanel(cornerRadius: 18)
    }
}

private extension View {
    @ViewBuilder
    func glassPanel(cornerRadius: CGFloat) -> some View {
        if #available(macOS 26.0, *) {
            self
                .padding(1)
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(.white.opacity(0.35), lineWidth: 1)
                )
        }
    }
}
