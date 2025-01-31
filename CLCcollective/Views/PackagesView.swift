import SwiftUI

private enum Layout {
    static let maxWidth: CGFloat = 500
    static let cardPadding: CGFloat = 24
    static let contentSpacing: CGFloat = 20
    static let cornerRadius: CGFloat = 20
    static let buttonHeight: CGFloat = 50
    static let cardWidth: CGFloat = UIScreen.main.bounds.width - 32
}

struct PackagesView: View {
    @StateObject private var viewModel = PackagesViewModel()
    @StateObject private var invoiceViewModel = InvoiceViewModel()
    @Binding var selectedTab: Int
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                SharedHeroBanner(selectedTab: $selectedTab)
                    .opacity(viewModel.isAppearing ? 1 : 0)
                    .offset(y: viewModel.isAppearing ? 0 : 50)
                
                // Main Content
                VStack(spacing: Layout.contentSpacing) {
                    // Create Invoice Button (only show if packages are selected)
                    if !viewModel.selectedPackages.isEmpty {
                        Button(action: {
                            if AuthenticationManager.shared.isAuthenticated {
                                createInvoiceAutomatically()
                            } else {
                                viewModel.showingAuthAlert = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text("Create Invoice (\(viewModel.selectedPackages.count) items)")
                                Text("$\(viewModel.totalAmount, specifier: "%.2f")")
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: Layout.buttonHeight)
                            .background(Color(hex: "#dca54e"))
                            .cornerRadius(Layout.cornerRadius)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal)
                        .disabled(invoiceViewModel.isCreatingInvoice)
                    }
                    
                    LazyVStack(spacing: Layout.contentSpacing, pinnedViews: []) {
                        ForEach(Package.allPackages) { package in
                            PackageCard(
                                package: package,
                                isSelected: viewModel.selectedPackages.contains(package),
                                onSelect: {
                                    viewModel.togglePackage(package)
                                }
                            )
                            .id(package.id)
                            .frame(width: min(Layout.cardWidth, Layout.maxWidth))
                        }
                    }
                    
                    // Copyright
                    VStack(spacing: 8) {
                        Text("© CLC Collective 2025")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Button(action: {
                            if let url = URL(string: "https://www.cochranfilms.com/privacy-policy") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Privacy Policy")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#dca54e"))
                                .underline()
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    .padding(.bottom, UIApplication.shared.firstKeyWindow?.safeAreaInsets.bottom ?? 0)
                }
                .padding(.vertical, Layout.cardPadding)
                .padding(.horizontal, 16)
            }
        }
        .background(
            Image("background_image")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.85))
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                viewModel.isAppearing = true
            }
        }
        .onDisappear {
            viewModel.isAppearing = false
        }
        
        if viewModel.showingAuthAlert {
            AuthRequiredPopup(isPresented: $viewModel.showingAuthAlert)
        }
        
        if invoiceViewModel.showCreatedPopup, 
           let urlString = invoiceViewModel.invoiceUrl,
           let _ = URL(string: urlString) {
            InvoiceCreatedPopup(invoiceUrl: urlString, viewModel: invoiceViewModel)
        }
    }
    
    private func createInvoiceAutomatically() {
        // Pre-fill client information from authenticated user
        var clientName = ""
        var clientEmail = ""
        
        if let email = AuthenticationManager.shared.userProfile?.email {
            clientEmail = email
            if !AuthenticationManager.shared.localUsername.isEmpty {
                clientName = AuthenticationManager.shared.localUsername
            } else if let name = AuthenticationManager.shared.userProfile?.name, !name.contains("@") {
                clientName = name
            }
        }
        
        // Create the description
        let description = viewModel.selectedPackages.map { package in
            """
            Package: \(package.title)
            Duration: \(package.subtitle)
            Description: \(package.description)
            """
        }.joined(separator: "\n\n")
        
        // Create the invoice
        Task { @MainActor in
            do {
                // Reset state
                invoiceViewModel.invoiceUrl = nil
                invoiceViewModel.currentInvoiceUrl = nil
                invoiceViewModel.showCreatedPopup = false
                invoiceViewModel.shouldNavigateToInvoices = false
                invoiceViewModel.error = nil
                
                withAnimation {
                    invoiceViewModel.isCreatingInvoice = true
                }
                
                // Set business name and wait for initialization
                WaveService.shared.setBusinessName("Cochran Films")
                
                // Create invoice with timeout
                try await withTimeout(seconds: 30) {
                    try await invoiceViewModel.createInvoice(
                        clientName: clientName,
                        clientEmail: clientEmail,
                        amount: viewModel.totalAmount,
                        serviceDescription: description,
                        invoiceTitle: "Package Bundle",
                        dueDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
                        notes: "",
                        quantity: 1
                    )
                }
                
                // Show the popup after successful creation
                withAnimation {
                    invoiceViewModel.showCreatedPopup = true
                }
                
                // Clear selections after successful creation
                withAnimation {
                    viewModel.clearSelections()
                }
            } catch {
                print("Error creating invoice: \(error.localizedDescription)")
                withAnimation {
                    invoiceViewModel.isCreatingInvoice = false
                    invoiceViewModel.error = error
                }
            }
        }
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw NSError(domain: "InvoiceError", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Invoice creation timed out. Please try again."
                ])
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

struct PackageCard: View {
    let package: Package
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var selectedOption: ServiceOption = .video
    @State private var showingContactForm = false
    
    enum ServiceOption {
        case video, podcast
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Layout.contentSpacing) {
            // Header with selection indicator
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(package.subtitle)
                        .font(.system(size: 24))
                        .threeDStyle(startColor: Color(hex: "#dca54e"), endColor: Color(hex: "#dca54e"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(package.title)
                        .font(.system(size: 32, weight: .bold))
                        .threeDStyle(startColor: .white, endColor: .white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(package.description)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .minimumScaleFactor(0.9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color(hex: "#dca54e") : .gray)
                    .font(.title2)
                    .padding(.leading, 8)
            }
            .frame(maxWidth: .infinity)
            
            // Price
            HStack {
                Text("$\(package.price)")
                    .font(.system(size: 32, weight: .bold))
                    .threeDStyle(startColor: Color(hex: "#dca54e"), endColor: Color(hex: "#dca54e"))
                    .fixedSize(horizontal: true, vertical: false)
                
                Text("/ package")
                    .font(.headline)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Service Option Picker
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose Your Service")
                    .font(.system(size: 20, weight: .bold))
                    .threeDStyle(startColor: .white, endColor: .white)
                    .fixedSize(horizontal: true, vertical: false)
                
                HStack(spacing: 16) {
                    ServiceOptionButton(
                        title: "Video",
                        icon: "video.fill",
                        isSelected: selectedOption == .video
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedOption = .video
                        }
                    }
                    
                    ServiceOptionButton(
                        title: "Podcast",
                        icon: "mic.fill",
                        isSelected: selectedOption == .podcast
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedOption = .podcast
                        }
                    }
                }
                .frame(height: Layout.buttonHeight)
            }
            .frame(maxWidth: .infinity)
            
            // Selected Option Details
            Group {
                if selectedOption == .video {
                    OptionView(
                        title: "Video Package",
                        icon: "video.fill",
                        description: package.videoOption
                    )
                } else {
                    OptionView(
                        title: "Podcast Package",
                        icon: "mic.fill",
                        description: package.podcastOption
                    )
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedOption)
            .frame(maxWidth: .infinity)
            
            // Additional Features
            if !package.additionalFeatures.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Additional Features")
                        .font(.system(size: 20, weight: .bold))
                        .threeDStyle(startColor: .white, endColor: .white)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    ForEach(package.additionalFeatures, id: \.self) { feature in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "#dca54e"))
                                .frame(width: 20, height: 20)
                            
                            Text(feature)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // Buttons row
            HStack(spacing: 16) {
                // Select Button
                Button(action: onSelect) {
                    Text(isSelected ? "Deselect" : "Select")
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .frame(height: Layout.buttonHeight)
                        .background(isSelected ? Color.black.opacity(0.2) : Color(hex: "#dca54e"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color(hex: "#dca54e"), lineWidth: isSelected ? 1 : 0)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Contact Button
                Button(action: {
                    showingContactForm = true
                }) {
                    Text("Contact Us")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: Layout.buttonHeight)
                        .background(Color(hex: "#dca54e"))
                        .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.top, 8)
        }
        .padding(Layout.cardPadding)
        .background(Color.black.opacity(0.3))
        .cornerRadius(Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .strokeBorder(Color(hex: "#dca54e").opacity(0.3), lineWidth: 1)
        )
        .sheet(isPresented: $showingContactForm) {
            ContactView()
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct ServiceOptionButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20, height: 20)
                Text(title)
                    .lineLimit(1)
            }
            .font(.headline)
            .foregroundColor(isSelected ? .black : .white)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.buttonHeight)
            .background(isSelected ? Color(hex: "#dca54e") : Color.black.opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(hex: "#dca54e"), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct OptionView: View {
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
            
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "#dca54e"))
                    .frame(width: 20, height: 20)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(3)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
}

#Preview {
    PackagesView(selectedTab: .constant(0))
        .preferredColorScheme(.dark)
} 