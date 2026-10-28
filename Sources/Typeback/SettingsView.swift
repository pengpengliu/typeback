import SwiftUI
import TypebackCore

struct SettingsView: View {
    @ObservedObject var controller: AppController
    @ObservedObject var preferences: PreferencesStore

    var body: some View {
        Form {
            Toggle(
                "启用自动切换",
                isOn: Binding(
                    get: { preferences.enabled },
                    set: controller.setEnabled
                )
            )

            HStack {
                Text("闲置时间")
                Spacer()
                TextField(
                    "秒",
                    value: Binding(
                        get: { preferences.idleSeconds },
                        set: controller.setIdleSeconds
                    ),
                    formatter: NumberFormatter.typebackInteger
                )
                .frame(width: 72)
                Stepper(
                    "",
                    value: Binding(
                        get: { preferences.idleSeconds },
                        set: controller.setIdleSeconds
                    ),
                    in: TypebackPreferences.minimumIdleSeconds...TypebackPreferences.maximumIdleSeconds
                )
                .labelsHidden()
                Text("秒")
                    .foregroundStyle(.secondary)
            }

            Picker(
                "自动切换到",
                selection: Binding(
                    get: { preferences.targetInputSourceID },
                    set: controller.setTargetInputSourceID
                )
            ) {
                if !controller.hasValidTargetInputSource {
                    Text("已失效：\(preferences.targetInputSourceID)")
                        .tag(preferences.targetInputSourceID)
                }

                ForEach(controller.inputSources) { source in
                    Text(source.localizedName)
                        .tag(source.id)
                }
            }

            Toggle(
                "开机自动启动",
                isOn: Binding(
                    get: { preferences.launchAtLogin },
                    set: controller.setLaunchAtLogin
                )
            )

            Divider()

            HStack {
                Text("权限")
                Spacer()
                Text(controller.hasAccessibilityPermission ? "已授权" : "需要 Accessibility 权限")
                    .foregroundStyle(controller.hasAccessibilityPermission ? Color.secondary : Color.red)
            }

            HStack {
                Button("打开系统设置") {
                    controller.openAccessibilitySettings()
                }
                Button("重新检查") {
                    controller.refreshSystemState()
                }
            }

            if let lastError = controller.lastError {
                Text(lastError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 440)
        .onAppear {
            controller.refreshSystemState()
        }
    }
}

private extension NumberFormatter {
    static var typebackInteger: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = TypebackPreferences.minimumIdleSeconds as NSNumber
        formatter.maximum = TypebackPreferences.maximumIdleSeconds as NSNumber
        return formatter
    }
}
