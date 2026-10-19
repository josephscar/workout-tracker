import SwiftUI

struct RootView: View {
    var libraryError: String?

    @Environment(PlanStore.self) private var store
    @State private var showLibraryError = false

    var body: some View {
        TabView {
            WeekView()
                .tabItem { Label("Plan", systemImage: "calendar") }
            LibraryView()
                .tabItem { Label("Exercises", systemImage: "dumbbell") }
        }
        .onAppear { showLibraryError = libraryError != nil }
        .alert("Couldn't load the exercise list", isPresented: $showLibraryError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(libraryError ?? "")
        }
        .alert("Couldn't save your plan", isPresented: Binding(
            get: { store.saveError != nil },
            set: { if !$0 { store.saveError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.saveError ?? "")
        }
    }
}

#Preview {
    RootView()
        .previewEnvironment()
}
