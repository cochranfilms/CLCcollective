import SwiftUI

struct FeaturedWorkSection: View {
    @StateObject private var featuredService = FeaturedService()
    @State private var currentIndex = 0
    
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 32) {
            // Section Header
            Text("Featured Work")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "#dca54e"))
                .frame(maxWidth: .infinity, alignment: .center)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
            
            if featuredService.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#dca54e")))
                    .scaleEffect(1.5)
            } else if let error = featuredService.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    Text("Failed to load featured work")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if featuredService.featuredItems.isEmpty {
                Text("No featured work available")
                    .font(.headline)
                    .foregroundColor(.gray)
            } else {
                // Featured Work Slider
                TabView(selection: $currentIndex) {
                    ForEach(Array(featuredService.featuredItems.enumerated()), id: \.element.id) { index, item in
                        FeaturedWorkCard(item: item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 400)
                .onReceive(timer) { _ in
                    withAnimation {
                        currentIndex = (currentIndex + 1) % max(1, featuredService.featuredItems.count)
                    }
                }
            }
        }
        .padding(.horizontal)
        .task {
            await featuredService.fetchFeaturedItems()
        }
    }
} 