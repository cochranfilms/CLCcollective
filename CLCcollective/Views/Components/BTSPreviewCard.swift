import SwiftUI
import SafariServices

struct BTSPreviewCard: View {
    @State private var showingSafariView = false
    private let btsURL = URL(string: "https://www.cochranfilms.com/bts")!
    private let brandGold = Color(hex: "#dca54e")
    
    var body: some View {
        Button {
            showingSafariView = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // BTS Image
                Image("tpain-BTS.jpg")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(brandGold, lineWidth: 2)
                    )
                    .cornerRadius(15)
                
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "video.fill")
                        .font(.title2)
                        .foregroundColor(brandGold)
                        .frame(width: 24, height: 24)
                    
                    Text("Behind The Scenes")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer(minLength: 16)
                    
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(brandGold)
                        .frame(width: 24, height: 24)
                }
                .frame(maxWidth: .infinity)
                
                // Description
                Text("Get an exclusive look at how we create cinematic content for our clients.")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(brandGold.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .sheet(isPresented: $showingSafariView) {
            SafariView(url: btsURL)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

#Preview {
    BTSPreviewCard()
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.black)
} 