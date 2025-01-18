import SwiftUI
import Auth0

struct ClientListView: View {
    @StateObject private var viewModel = ClientListViewModel()
    @State private var showingCreateUser = false
    @State private var isAppearing = false
    private let brandGold = Color(hex: "#dca54e")
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("Clients")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(brandGold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 60)
                        .padding(.horizontal)
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 20)
                    
                    // Create User Button
                    Button(action: {
                        showingCreateUser = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Create New User")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(brandGold)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(brandGold.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    .opacity(isAppearing ? 1 : 0)
                    .offset(y: isAppearing ? 0 : 20)
                    
                    // Client List
                    VStack(spacing: 16) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: brandGold))
                                .scaleEffect(1.5)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 50)
                        } else if viewModel.clients.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(brandGold.opacity(0.5))
                                
                                Text("No clients found")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(brandGold.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        } else {
                            ForEach(Array(viewModel.clients.enumerated()), id: \.element.id) { index, client in
                                NavigationLink(destination: AdminUserDetailView(user: client, onUserDeleted: { deletedUserId in
                                    viewModel.removeClient(withId: deletedUserId)
                                })) {
                                    ClientCard(client: client)
                                }
                                .opacity(isAppearing ? 1 : 0)
                                .offset(y: isAppearing ? 0 : 20)
                                .animation(.easeOut.delay(Double(index) * 0.1), value: isAppearing)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .background(
                Image("background_image")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(Color.black.opacity(0.85))
                    .ignoresSafeArea()
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showingCreateUser) {
            CreateUserView(isPresented: $showingCreateUser, viewModel: viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .task {
            await viewModel.fetchClients()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAppearing = true
            }
        }
        .onDisappear {
            isAppearing = false
        }
    }
}

struct CreateUserView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ClientListViewModel
    @State private var email = ""
    @State private var password = ""
    
    private let brandGold = Color(hex: "#dca54e")
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("User Details")) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section {
                    Button(action: createUser) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Create User")
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty)
                }
            }
            .navigationTitle("Create New User")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    isPresented = false
                }
            )
        }
    }
    
    private func createUser() {
        Task {
            await viewModel.createUser(email: email, password: password)
            if viewModel.error == nil {
                isPresented = false
            }
        }
    }
}

struct ClientCard: View {
    let client: Auth0User
    private let brandGold = Color(hex: "#dca54e")
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(brandGold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(client.name ?? "No Name")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(client.email ?? "No Email")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(brandGold)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(brandGold.opacity(0.3), lineWidth: 1)
        )
    }
} 