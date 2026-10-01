import SwiftUI

// The @main entry point belongs to the (not yet created) Xcode app target;
// this library only provides the scene so it can be built with `swift build`.
public struct JsonconverterApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
