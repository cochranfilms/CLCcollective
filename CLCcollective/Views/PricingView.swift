import SwiftUI
import Auth0
import SafariServices

private enum Layout {
    static let maxWidth: CGFloat = 500
    static let cardPadding: CGFloat = 24
    static let contentSpacing: CGFloat = 20
    static let cornerRadius: CGFloat = 20
    static let buttonHeight: CGFloat = 50
    static let cardWidth: CGFloat = UIScreen.main.bounds.width - 32
}

// MARK: - Main View
struct PricingView: View {
    @State private var isAppearing = false
    @StateObject private var invoiceViewModel = InvoiceViewModel()
    @State private var selectedItems: Set<String> = []
    @State private var showingAuthAlert = false
    @State private var shootingHours = 1
    @Binding var selectedTab: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        SharedHeroBanner(selectedTab: $selectedTab)
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 50)
                        
                        VStack(spacing: Layout.contentSpacing) {
                            if !selectedItems.isEmpty {
                                let totalAmount = selectedItems.reduce(0.0) { total, itemId in
                                    if let item = findItemById(itemId) {
                                        if item.title == "Shooting" {
                                            return total + (item.price * Double(shootingHours))
                                        }
                                        return total + item.price
                                    }
                                    return total
                                }
                                
                                CreateInvoiceButton(
                                    selectedItems: selectedItems,
                                    totalAmount: totalAmount,
                                    showingInvoiceForm: .constant(false),
                                    showingAuthAlert: $showingAuthAlert
                                )
                            }
                            
                            LazyVStack(spacing: 0) {
                                VStack(spacing: 0) {
                                    VStack(spacing: 4) {
                                        Text("Course Creator")
                                            .font(.system(size: 40, weight: .bold))
                                            .threeDStyle(startColor: Color(hex: "1c00ff"), endColor: Color(hex: "1c00ff"))
                                            .shadow(color: .white.opacity(0.2), radius: 10, x: 0, y: 0)
                                        Text("Academy")
                                            .font(.system(size: 40, weight: .bold))
                                            .threeDStyle(startColor: Color(hex: "1c00ff"), endColor: Color(hex: "1c00ff"))
                                            .shadow(color: .white.opacity(0.2), radius: 10, x: 0, y: 0)
                                    }
                                    .padding(.bottom, -8)
                                    
                                    Image("cca-logo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 200, height: 200)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                
                                // Category Cards - Show Course Creator Academy first
                                ForEach(PricingService.categories) { category in
                                    if category.title == "Course Creator Academy" {
                                        PricingPackageCard(
                                            title: "In-Person Film Education",  // Updated title
                                            items: category.items,
                                            note: category.note,
                                            selectedItems: $selectedItems,
                                            shootingHours: $shootingHours
                                        )
                                        .frame(width: min(Layout.cardWidth, Layout.maxWidth))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            
                            // Cochran Films Title and Logo
                            VStack(spacing: 32) {
                                Text("Cochran Films")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(Color(hex: "#dca54e"))
                                
                                // Cochran Films Logo
                                Image("cf-logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150, height: 150)
                                    .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 0)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 32)
                            
                            // Base Services Card
                            PricingPackageCard(
                                title: "Base Prices",  // Added title here
                                items: PricingService.additionalServices,
                                selectedItems: $selectedItems,
                                shootingHours: $shootingHours
                            )
                            .frame(width: min(Layout.cardWidth, Layout.maxWidth))
                            
                            // Remaining Categories
                            ForEach(PricingService.categories) { category in
                                if category.title != "Course Creator Academy" {
                                    PricingPackageCard(
                                        title: category.title,
                                        items: category.items,
                                        note: category.note,
                                        selectedItems: $selectedItems,
                                        shootingHours: $shootingHours
                                    )
                                    .frame(width: min(Layout.cardWidth, Layout.maxWidth))
                                }
                            }
                            
                            Text("© CLC Collective 2025")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 20)
                                .padding(.bottom, 40)
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
                
                if showingAuthAlert {
                    AuthRequiredPopup(isPresented: $showingAuthAlert)
                }
                
                if invoiceViewModel.showCreatedPopup, let url = invoiceViewModel.invoiceUrl {
                    InvoiceCreatedPopup(invoiceUrl: url, viewModel: invoiceViewModel)
                }
            }
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
    
    private func findItemById(_ itemId: String) -> PricingItem? {
        if let item = PricingService.additionalServices.first(where: { $0.id.uuidString == itemId }) {
            return item
        }
        for category in PricingService.categories {
            if let item = category.items.first(where: { $0.id.uuidString == itemId }) {
                return item
            }
        }
        return nil
    }
}

struct PricingPackageCard: View {
    let title: String
    let items: [PricingItem]
    var note: String?
    @Binding var selectedItems: Set<String>
    @Binding var shootingHours: Int
    @State private var showingContactForm = false
    
    private func getButtonStyle(for item: PricingItem) -> (backgroundColor: Color, textColor: Color) {
        // Check if this is a Course Creator Academy item
        if PricingService.categories.first(where: { $0.title == "Course Creator Academy" })?.items.contains(where: { $0.id == item.id }) == true {
            return (Color(hex: "1c00ff"), .white)
        }
        // Default style for other items
        return (Color(hex: "#dca54e"), .black)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Layout.contentSpacing) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if let note = note {
                    Text(note)
                        .font(.headline)
                        .foregroundColor(Color(hex: "#dca54e"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
            }
            
            // Service Items
            VStack(spacing: 16) {
                ForEach(items) { item in
                    VStack {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                if let description = item.description {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(item.priceString)
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "#dca54e"))
                                
                                Button(action: {
                                    if selectedItems.contains(item.id.uuidString) {
                                        selectedItems.remove(item.id.uuidString)
                                    } else {
                                        selectedItems.insert(item.id.uuidString)
                                    }
                                }) {
                                    let style = getButtonStyle(for: item)
                                    Text(selectedItems.contains(item.id.uuidString) ? "Selected" : "Select")
                                        .font(.subheadline)
                                        .foregroundColor(selectedItems.contains(item.id.uuidString) ? style.textColor : style.textColor)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedItems.contains(item.id.uuidString) ? style.backgroundColor.opacity(0.8) : style.backgroundColor)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .strokeBorder(style.backgroundColor, lineWidth: selectedItems.contains(item.id.uuidString) ? 1 : 0)
                                        )
                                }
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(12)
                        
                        if item.title == "Shooting" && selectedItems.contains(item.id.uuidString) {
                            let formattedPrice = String(format: "$%.2f", item.price * Double(shootingHours))
                            Stepper(
                                "Hours: \(shootingHours) (+\(formattedPrice))",
                                value: $shootingHours,
                                in: 1...8
                            )
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                        }
                    }
                }
            }
            
            // Contact Button
            Button(action: { showingContactForm = true }) {
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

// MARK: - Create Invoice Button
private struct CreateInvoiceButton: View {
    let selectedItems: Set<String>
    let totalAmount: Double
    @Binding var showingInvoiceForm: Bool
    @Binding var showingAuthAlert: Bool
    @StateObject private var invoiceViewModel = InvoiceViewModel()
    @ObservedObject private var authManager = AuthenticationManager.shared
    @State private var clientName = ""
    @State private var clientEmail = ""
    
    var body: some View {
        ZStack {
            Button(action: {
                if AuthenticationManager.shared.isAuthenticated {
                    // Pre-fill client information from authenticated user
                    if let email = authManager.userProfile?.email {
                        clientEmail = email
                        if !authManager.localUsername.isEmpty {
                            clientName = authManager.localUsername
                        } else if let name = authManager.userProfile?.name, !name.contains("@") {
                            clientName = name
                        }
                    }
                    createInvoiceForSelectedItems()
                } else {
                    showingAuthAlert = true
                }
            }) {
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text("Create Invoice (\(selectedItems.count) items)")
                    Text("$\(totalAmount, specifier: "%.2f")")
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
            
            // Add the popup overlay
            if invoiceViewModel.showCreatedPopup, 
               let urlString = invoiceViewModel.invoiceUrl,
               let url = URL(string: urlString) {
                PopupOverlay(url: url, viewModel: invoiceViewModel)
            }
        }
    }
    
    private func createInvoiceForSelectedItems() {
        let hasCourseCreatorItems = selectedItems.contains { itemId in
            guard let item = findItemById(itemId) else { return false }
            // Check if the item is from the Course Creator Academy category
            for category in PricingService.categories {
                if category.title == "Course Creator Academy" {
                    return category.items.contains { $0.id.uuidString == itemId }
                }
            }
            return false
        }
        
        let selectedItemDetails = selectedItems.compactMap { itemId -> (title: String, description: String, price: Double)? in
            guard let item = findItemById(itemId) else { return nil }
            return (item.title, "\(item.title) - \(item.priceString)", item.price)
        }
        
        // Show loading state
        withAnimation {
            invoiceViewModel.isCreatingInvoice = true
        }
        
        Task {
            do {
                // Set the correct business name and create invoice
                if hasCourseCreatorItems {
                    print("Creating Course Creator Academy invoice...")
                    WaveService.shared.setBusinessName("Course Creator Academy LLC")
                    
                    // Use the actual service name for the line item
                    let description = selectedItemDetails.map { "\($0.title) - \($0.price)" }.joined(separator: "\n")
                    let totalAmount = selectedItemDetails.reduce(0.0) { $0 + $1.price }
                    
                    try await invoiceViewModel.createInvoice(
                        clientName: clientName,
                        clientEmail: clientEmail,
                        amount: totalAmount,
                        serviceDescription: description,
                        invoiceTitle: "CCA Education", // This is the invoice title at the top
                        dueDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
                        notes: "",
                        quantity: 1
                    )
                } else {
                    print("Creating Cochran Films invoice...")
                    WaveService.shared.setBusinessName("Cochran Films")
                    
                    let description = selectedItemDetails.map { "\($0.title) - \($0.price)" }.joined(separator: "\n")
                    let totalAmount = selectedItemDetails.reduce(0.0) { $0 + $1.price }
                    
                    try await invoiceViewModel.createInvoice(
                        clientName: clientName,
                        clientEmail: clientEmail,
                        amount: totalAmount,
                        serviceDescription: description,
                        invoiceTitle: "Video Production Services",
                        dueDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
                        notes: "",
                        quantity: 1
                    )
                }
            } catch {
                print("Error creating invoice: \(error.localizedDescription)")
                await MainActor.run {
                    invoiceViewModel.error = error
                    invoiceViewModel.isCreatingInvoice = false
                }
            }
        }
    }
    
    private func findItemById(_ itemId: String) -> PricingItem? {
        if let item = PricingService.additionalServices.first(where: { $0.id.uuidString == itemId }) {
            return item
        }
        for category in PricingService.categories {
            if let item = category.items.first(where: { $0.id.uuidString == itemId }) {
                return item
            }
        }
        return nil
    }
}

// MARK: - Invoice Form View
private struct InvoiceFormView: View {
    let selectedItems: Set<String>
    let totalAmount: Double
    @Binding var clientName: String
    @Binding var clientEmail: String
    @Binding var invoiceTitle: String
    @Binding var notes: String
    @Binding var dueDate: Date
    @Binding var showingInvoiceForm: Bool
    @ObservedObject var invoiceViewModel: InvoiceViewModel
    @Binding var shootingHours: Int
    @ObservedObject private var authManager = AuthenticationManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Client Information")) {
                    TextField("Client Name", text: $clientName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                    TextField("Client Email", text: $clientEmail)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
                
                Section(header: Text("Invoice Details")) {
                    TextField("Project Name", text: $invoiceTitle)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }
                
                Section(header: Text("Selected Items")) {
                    ForEach(Array(selectedItems), id: \.self) { itemId in
                        if let item = findItemById(itemId) {
                            HStack {
                                if item.title == "Shooting" {
                                    Text("\(item.title) (\(shootingHours) hours)")
                                    Spacer()
                                    Text("$\(item.price * Double(shootingHours), specifier: "%.2f")")
                                } else {
                                    Text(item.title)
                                    Spacer()
                                    Text("$\(item.price, specifier: "%.2f")")
                                }
                            }
                        }
                    }
                    HStack {
                        Text("Total")
                            .fontWeight(.bold)
                        Spacer()
                        Text("$\(calculateTotalAmount(), specifier: "%.2f")")
                            .fontWeight(.bold)
                    }
                }
                
                Section(header: Text("Project Description")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.sentences)
                }
                
                Section {
                    Button(action: createInvoice) {
                        if invoiceViewModel.isCreatingInvoice {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Text("Generate Invoice")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(clientName.isEmpty || clientEmail.isEmpty || invoiceViewModel.isCreatingInvoice)
                }
            }
            .navigationTitle("Create Invoice")
            .navigationBarItems(trailing: Button("Cancel") {
                showingInvoiceForm = false
            })
            .onAppear {
                // Pre-fill client information from authenticated user
                if clientName.isEmpty {
                    if !authManager.localUsername.isEmpty {
                        clientName = authManager.localUsername
                    } else if let name = authManager.userProfile?.name {
                        clientName = name
                    }
                }
                if clientEmail.isEmpty, let email = authManager.userProfile?.email {
                    clientEmail = email
                }
            }
        }
    }
    
    private func calculateTotalAmount() -> Double {
        selectedItems.reduce(0.0) { total, itemId in
            if let item = findItemById(itemId) {
                if item.title == "Shooting" {
                    return total + (item.price * Double(shootingHours))
                }
                return total + item.price
            }
            return total
        }
    }
    
    private func findItemById(_ itemId: String) -> PricingItem? {
        // Check Additional Services first
        if let item = PricingService.additionalServices.first(where: { $0.id.uuidString == itemId }) {
            return item
        }
        
        // Then check all categories
        for category in PricingService.categories {
            if let item = category.items.first(where: { $0.id.uuidString == itemId }) {
                return item
            }
        }
        return nil
    }
    
    private func createInvoice() {
        Task {
            do {
                let description = selectedItems.compactMap { itemId -> String? in
                    guard let item = findItemById(itemId) else { return nil }
                    if item.title == "Shooting" {
                        let formattedPrice = String(format: "$%.2f", item.price * Double(shootingHours))
                        return "\(item.title) (\(shootingHours) hours) - \(formattedPrice)"
                    }
                    return "\(item.title) - \(item.priceString)"
                }.joined(separator: "\n")
                
                let totalAmount = calculateTotalAmount()
                
                print("Creating invoice with total amount: \(totalAmount)")
                print("Selected items:")
                selectedItems.forEach { itemId in
                    if let item = findItemById(itemId) {
                        if item.title == "Shooting" {
                            let formattedPrice = String(format: "$%.2f", item.price * Double(shootingHours))
                            print("- \(item.title) (\(shootingHours) hours): \(formattedPrice)")
                        } else {
                            print("- \(item.title): \(item.priceString)")
                        }
                    }
                }
                
                try await invoiceViewModel.createInvoice(
                    clientName: clientName,
                    clientEmail: clientEmail,
                    amount: totalAmount,
                    serviceDescription: description,
                    invoiceTitle: invoiceTitle.isEmpty ? "Custom Package" : invoiceTitle,
                    dueDate: dueDate,
                    notes: notes,
                    quantity: 1
                )
            } catch {
                print("Error creating invoice: \(error.localizedDescription)")
                await MainActor.run {
                    invoiceViewModel.error = error
                    invoiceViewModel.isCreatingInvoice = false
                }
            }
        }
    }
}

#Preview {
    PricingView(selectedTab: .constant(0))
        .preferredColorScheme(.dark)
} 
