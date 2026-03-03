import SwiftUI
import GameKit

@main
struct AbsolutelyNotApp: App {
    @State private var isGameCenterAuthenticated = false

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                GameSetupView()
            }
            .onAppear {
                authenticateGameCenter()
            }
        }
    }

    private func authenticateGameCenter() {
        GameCenterService.authenticate { success in
            isGameCenterAuthenticated = success
        }
    }
}
