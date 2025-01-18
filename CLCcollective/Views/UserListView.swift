import SwiftUI

struct UserListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ClientListViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color(hex: "#dca54e"))
                } else if viewModel.clients.isEmpty {
                    Text("No users found")
                        .foregroundColor(.gray)
                } else {
                    ForEach(viewModel.clients) { user in
                        if user.email != nil {
                            NavigationLink(destination: AdminUserDetailView(user: user)) {
                                UserRow(user: user)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .task {
            await viewModel.fetchClients()
        }
    }
}

struct UserRow: View {
    let user: Auth0User
    private let brandGold = Color(hex: "#dca54e")
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(brandGold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name ?? "No Name")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(user.email ?? "No Email")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(brandGold)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(brandGold, lineWidth: 1)
        )
    }
} 
