import SwiftUI
import SafariServices

private enum Layout {
    static let maxWidth: CGFloat = 500
    static let cardPadding: CGFloat = 24
    static let contentSpacing: CGFloat = 20
    static let cornerRadius: CGFloat = 20
    static let buttonHeight: CGFloat = 50
}

struct InvoiceCreatedPopup: View {
    let invoiceUrl: String
    @ObservedObject var viewModel: InvoiceViewModel
    @State private var showingSafariView = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Prevent closing by tapping outside
                }
            
            VStack(spacing: 24) {
                // Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#dca54e"))
                
                // Title
                Text("Invoice Created!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                // Message
                Text("Your invoice has been created successfully. Would you like to pay now or later?")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Buttons
                VStack(spacing: 16) {
                    // Pay Now Button
                    Button(action: {
                        print("Opening URL: \(invoiceUrl)")
                        showingSafariView = true
                    }) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                            Text("Pay Now")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(height: Layout.buttonHeight)
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#dca54e"))
                        .cornerRadius(Layout.cornerRadius)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Pay Later Button
                    Button(action: {
                        viewModel.handlePayLater()
                        dismiss() // Dismiss the current view
                    }) {
                        HStack {
                            Image(systemName: "clock.fill")
                            Text("Pay Later")
                        }
                        .font(.headline)
                        .foregroundColor(Color(hex: "#dca54e"))
                        .frame(height: Layout.buttonHeight)
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                                .stroke(Color(hex: "#dca54e"), lineWidth: 1)
                        )
                        .cornerRadius(Layout.cornerRadius)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.top)
            }
            .padding(32)
            .background(Color.black.opacity(0.95))
            .cornerRadius(Layout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(Color(hex: "#dca54e").opacity(0.3), lineWidth: 1)
            )
            .padding(24)
        }
        .sheet(isPresented: $showingSafariView, onDismiss: {
            // Dismiss the current view and navigate to InvoicesView
            viewModel.handlePayNow()
            dismiss() // Dismiss the current view
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.shouldNavigateToInvoices = true
            }
        }) {
            SafariView(url: URL(string: invoiceUrl)!)
        }
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - Loading View Component
struct InvoiceLoadingView: View {
    let message: String
    let isAppearing: Bool
    
    var body: some View {
        HStack {
            ProgressView()
                .tint(Color(hex: "#dca54e"))
            Text(message)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(hex: "#dca54e").opacity(0.3), lineWidth: 1)
        )
        .opacity(isAppearing ? 1 : 0)
        .offset(y: isAppearing ? 0 : 30)
    }
}

// MARK: - Error View Component
struct InvoiceErrorView: View {
    let error: Error
    let isAppearing: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#dca54e"))
            
            Text(error.localizedDescription)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.black.opacity(0.6))
        .cornerRadius(Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(hex: "#dca54e").opacity(0.3), lineWidth: 1)
        )
        .opacity(isAppearing ? 1 : 0)
        .offset(y: isAppearing ? 0 : 30)
    }
}

// MARK: - Auth Alert Popup
struct AuthRequiredPopup: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#dca54e"))
                
                // Title
                Text("Authentication Required")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                // Message
                Text("You must be logged in to create an invoice.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // OK Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }) {
                    Text("OK")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(height: Layout.buttonHeight)
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#dca54e"))
                        .cornerRadius(Layout.cornerRadius)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(32)
            .background(Color.black.opacity(0.95))
            .cornerRadius(Layout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(Color(hex: "#dca54e").opacity(0.3), lineWidth: 1)
            )
            .padding(24)
        }
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - Invoice List Item View
private struct InvoiceListItemView: View {
    let invoice: Invoice
    let onDelete: () -> Void
    let onOpen: () -> Void
    
    var body: some View {
        Button(action: onOpen) {
            InvoiceRowView(
                invoice: invoice,
                onDelete: onDelete,
                onOpen: onOpen
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Empty Invoice List View
private struct EmptyInvoiceListView: View {
    var body: some View {
        Text("No invoices found")
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black.opacity(0.6))
            .cornerRadius(Layout.cornerRadius)
    }
}

// MARK: - Invoice List Header
private struct InvoiceListHeader: View {
    var body: some View {
        Text("Your Invoices")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(Color(hex: "#dca54e"))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 8)
    }
}

// MARK: - Main Content View
struct InvoiceContentView: View {
    let invoices: [Invoice]
    let isAppearing: Bool
    let onDelete: (Invoice) -> Void
    let onOpen: (Invoice) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            InvoiceListHeader()
            
            if invoices.isEmpty {
                EmptyInvoiceListView()
            } else {
                ForEach(invoices, id: \.uniqueId) { invoice in
                    InvoiceListItemView(
                        invoice: invoice,
                        onDelete: { onDelete(invoice) },
                        onOpen: { onOpen(invoice) }
                    )
                }
            }
        }
        .opacity(isAppearing ? 1 : 0)
        .offset(y: isAppearing ? 0 : 30)
    }
}

// MARK: - Main View
struct InvoicesView: View {
    @StateObject private var viewModel = InvoiceViewModel()
    @State private var showingSafariView = false
    @State private var selectedInvoiceUrl: String?
    @State private var isOpeningInvoice = false
    @State private var isAppearing = false
    @State private var showingDeleteConfirmation = false
    @State private var invoiceToDelete: Invoice?
    @State private var showingCostEstimator = false
    @State private var showingAuthAlert = false
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""
    @ObservedObject private var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int
    
    // View builders
    @ViewBuilder
    private func createInvoiceButton() -> some View {
        Button(action: handleCreateInvoiceAction) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Create Invoice")
            }
            .font(.headline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.buttonHeight)
            .background(Color(hex: "#dca54e"))
            .cornerRadius(Layout.cornerRadius)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func loadingOrContentView() -> some View {
        if viewModel.isLoadingInvoices || isOpeningInvoice {
            InvoiceLoadingView(
                message: viewModel.isLoadingInvoices ? "Loading invoices..." : "Opening invoice...",
                isAppearing: isAppearing
            )
        }
        
        if !viewModel.isLoadingInvoices {
            InvoiceContentView(
                invoices: viewModel.invoices,
                isAppearing: isAppearing,
                onDelete: handleInvoiceDeletion,
                onOpen: handleInvoiceOpening
            )
        }
        
        if let error = viewModel.error {
            InvoiceErrorView(error: error, isAppearing: isAppearing)
        }
    }
    
    // Action handlers
    private func handleCreateInvoiceAction() {
        if AuthenticationManager.shared.isAuthenticated {
            showingCostEstimator = true
        } else {
            withAnimation {
                showingAuthAlert = true
            }
        }
    }
    
    private func handleInvoiceDeletion(_ invoice: Invoice) {
        invoiceToDelete = invoice
        showingDeleteConfirmation = true
    }
    
    private func handleInvoiceOpening(_ invoice: Invoice) {
        guard !isOpeningInvoice else { return }
        
        isOpeningInvoice = true
        selectedInvoiceUrl = invoice.viewUrl
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showingSafariView = true
        }
    }
    
    // MARK: - Background View
    private struct BackgroundView: View {
        let geometry: GeometryProxy
        
        var body: some View {
            Image("background_image")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .overlay(Color.black.opacity(0.85))
                .edgesIgnoringSafeArea(.all)
        }
    }
    
    // MARK: - Main Content Stack
    private struct MainContentStack: View {
        let isAppearing: Bool
        let createInvoiceButton: () -> AnyView
        let loadingOrContentView: () -> AnyView
        @Binding var selectedTab: Int
        
        var body: some View {
            LazyVStack(spacing: 0) {
                SharedHeroBanner(selectedTab: $selectedTab)
                    .opacity(isAppearing ? 1 : 0)
                    .offset(y: isAppearing ? 0 : 50)
                
                LazyVStack(spacing: Layout.contentSpacing * 2) {
                    createInvoiceButton()
                    loadingOrContentView()
                    
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
    }
    
    // MARK: - Overlay Views
    private struct OverlayViews: View {
        @Binding var showingAuthAlert: Bool
        @ObservedObject var viewModel: InvoiceViewModel
        
        var body: some View {
            ZStack {
                if showingAuthAlert {
                    AuthRequiredPopup(isPresented: $showingAuthAlert)
                        .transition(.opacity.combined(with: .scale))
                        .zIndex(999)
                }
                
                if viewModel.showCreatedPopup, let url = viewModel.invoiceUrl {
                    Color.black.opacity(0.8)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                    
                    InvoiceCreatedPopup(invoiceUrl: url, viewModel: viewModel)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.showCreatedPopup)
            .animation(.easeInOut(duration: 0.3), value: showingAuthAlert)
        }
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        SharedHeroBanner(selectedTab: $selectedTab)
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 50)
                        
                        LazyVStack(spacing: Layout.contentSpacing * 2) {
                            createInvoiceButton()
                            loadingOrContentView()
                            
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
                .background(BackgroundView(geometry: geometry))
                .ignoresSafeArea(.container, edges: .top)
            }
            .homePageStyle()
            
            OverlayViews(showingAuthAlert: $showingAuthAlert, viewModel: viewModel)
        }
        .sheet(isPresented: $showingCostEstimator, onDismiss: handleCostEstimatorDismiss) {
            CostEstimatorView()
        }
        .sheet(isPresented: $showingSafariView, onDismiss: handleSafariViewDismiss) {
            if let urlString = selectedInvoiceUrl,
               let url = URL(string: urlString) {
                SafariView(url: url)
                    .edgesIgnoringSafeArea(.all)
                    .onDisappear {
                        isOpeningInvoice = false
                        selectedInvoiceUrl = nil
                    }
            } else {
                Text("Unable to open invoice")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .task {
            await handleInitialLoad()
        }
        .onDisappear {
            isAppearing = false
        }
        .onChange(of: authManager.isAuthenticated, handleAuthChange)
        .onChange(of: viewModel.invoiceUrl, handleInvoiceUrlChange)
        .onChange(of: viewModel.shouldNavigateToInvoices, handleNavigationChange)
        .onReceive(NotificationCenter.default.publisher(for: .switchToBillingTab), perform: handleBillingTabSwitch)
        .refreshable {
            await viewModel.fetchInvoices()
        }
        .confirmationDialog(
            "Delete Invoice",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                handleDeleteConfirmation()
            } label: {
                Text("Delete")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this invoice? This action cannot be undone.")
        }
        .alert("Error Deleting Invoice", isPresented: $showingDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
    }
    
    // MARK: - Event Handlers
    private func handleCostEstimatorDismiss() {
        if viewModel.invoiceUrl != nil {
            print("CostEstimator dismissed with invoice URL")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.showCreatedPopup = true
                }
            }
        }
        Task {
            await viewModel.fetchInvoices()
        }
    }
    
    private func handleSafariViewDismiss() {
        isOpeningInvoice = false
        selectedInvoiceUrl = nil
    }
    
    private func handleInitialLoad() async {
        withAnimation(.easeOut(duration: 0.8)) {
            isAppearing = true
        }
        if authManager.isAuthenticated {
            await viewModel.fetchInvoices()
        }
    }
    
    private func handleAuthChange(oldValue: Bool, newValue: Bool) {
        if newValue {
            print("User authenticated, fetching invoices...")
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await viewModel.fetchInvoices()
            }
        } else {
            print("User logged out, clearing invoices...")
            viewModel.invoices = []
            // Disconnect any invoice connections from projects
            Task {
                let projectViewModel = ProjectViewModel()
                for project in projectViewModel.projects {
                    if project.invoiceId != nil {
                        await projectViewModel.disconnectInvoice(invoiceId: project.invoiceId!)
                    }
                }
            }
        }
    }
    
    private func handleInvoiceUrlChange(oldValue: String?, newValue: String?) {
        if let _ = newValue {
            print("New invoice URL detected...")
        }
    }
    
    private func handleNavigationChange(oldValue: Bool, newValue: Bool) {
        if newValue {
            dismiss()
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await viewModel.fetchInvoices()
            }
        }
    }
    
    private func handleBillingTabSwitch(_ notification: Notification) {
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await viewModel.fetchInvoices()
        }
    }
    
    private func handleDeleteConfirmation() {
        if let invoice = invoiceToDelete {
            Task {
                do {
                    try await viewModel.deleteInvoice(invoice)
                    await viewModel.fetchInvoices()
                } catch let error as WaveError {
                    deleteErrorMessage = error.localizedDescription
                    showingDeleteError = true
                } catch {
                    deleteErrorMessage = "Failed to delete invoice: \(error.localizedDescription)"
                    showingDeleteError = true
                }
            }
        }
    }
}

#Preview {
    InvoicesView(selectedTab: .constant(0))
        .preferredColorScheme(.dark)
} 