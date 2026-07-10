import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
            ExploreView()
                .tabItem { Label("Explore", systemImage: "magnifyingglass") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "house.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                Text("Jsonconverter")
                    .font(.largeTitle.bold())
                Text("Jsonconverter — Mobile app (swiftui)")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

struct ExploreView: View {
    var body: some View {
        NavigationStack {
            Text("Explore Jsonconverter")
                .navigationTitle("Explore")
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.tint)
                Text("Chaowalit Greepoke")
                    .font(.title2.bold())
                Link("bookchaowalit.com", destination: URL(string: "https://bookchaowalit.com")!)
            }
            .navigationTitle("Profile")
        }
    }
}
