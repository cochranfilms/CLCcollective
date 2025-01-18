import SwiftUI

struct FeaturedBrand: Identifiable {
    let id = UUID()
    let name: String
    let logoName: String
    let url: String
    let description: String
    let shouldInvertColor: Bool
    let logoHeight: CGFloat
}

struct FeaturedOnSection: View {
    private let featuredBrands: [FeaturedBrand] = [
        FeaturedBrand(
            name: "Russell Innovation Center for Entrepreneurs",
            logoName: "RICE_Logo",
            url: "https://www.russellcenter.org",
            description: "An economic mobility engine for the community: driving Black entrepreneurs and small business owners to innovate, grow, create jobs, and build wealth.",
            shouldInvertColor: false,
            logoHeight: 80
        ),
        FeaturedBrand(
            name: "iHeart Radio",
            logoName: "iHeart_Logo",
            url: "https://www.iheart.com",
            description: "iHeartMedia is the #1 audio company in the United States.",
            shouldInvertColor: false,
            logoHeight: 80
        ),
        FeaturedBrand(
            name: "Pylon 7v7",
            logoName: "Pylon_Logo",
            url: "https://www.pylon7on7.com",
            description: "A non-contact, competitive football league that provides a platform for high school and youth athletes to develop their skills and get noticed by college programs",
            shouldInvertColor: false,
            logoHeight: 80
        )
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            // Section Header
            Text("Featured On")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "#dca54e"))
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Brands Grid
            LazyVGrid(columns: [
                GridItem(.flexible())
            ], spacing: 24) {
                ForEach(featuredBrands) { brand in
                    Button(action: {
                        if let url = URL(string: brand.url) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        VStack(spacing: 16) {
                            Image(brand.logoName)
                                .resizable()
                                .scaledToFit()
                                .frame(height: brand.logoHeight)
                                .modifier(LogoModifier(shouldInvertColor: brand.shouldInvertColor))
                            
                            Text(brand.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                            
                            if !brand.description.isEmpty {
                                Text(brand.description)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "#dca54e"))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            // Visit Website Button
                            Button(action: {
                                if let url = URL(string: brand.url) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("Visit Website")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(height: 44)
                                    .frame(maxWidth: .infinity)
                                    .background(AppStyle.Colors.brandYellow)
                                    .cornerRadius(10)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 8)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(
                            ZStack {
                                Image("Categories_BG")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .opacity(0.25)
                                Color.black.opacity(0.3)
                                
                                // White gradient overlay
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.15),
                                        Color.white.opacity(0.08)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppStyle.Colors.brandYellow, lineWidth: 2)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .padding(.horizontal)
    }
}

struct LogoModifier: ViewModifier {
    let shouldInvertColor: Bool
    
    func body(content: Content) -> some View {
        if shouldInvertColor {
            content
                .colorInvert()
                .opacity(0.9)
        } else {
            content
                .opacity(0.9)
        }
    }
}

#Preview {
    FeaturedOnSection()
        .preferredColorScheme(.dark)
        .padding()
        .background(Color.black)
} 