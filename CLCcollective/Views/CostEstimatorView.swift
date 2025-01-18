import SwiftUI
import Auth0
import SafariServices

struct CostEstimatorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCompany = "Cochran Films"
    @State private var selectedCategory = "Events"
    @State private var selectedService = "2 Hours"
    @State private var needsRawFiles = false
    @State private var additionalHours = 0
    @State private var extraCameras = 0
    @State private var showingContactForm = false
    @StateObject private var invoiceViewModel = InvoiceViewModel()
    @State private var showingInvoiceForm = false
    @State private var showingInvoiceUrl = false
    @State private var clientName = ""
    @State private var clientEmail = ""
    @State private var invoiceTitle = ""
    @State private var dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var notes = ""
    @State private var quantity = 1
    
    private let companies = ["Cochran Films", "Course Creator Academy"]
    
    private var categories: [String] {
        switch selectedCompany {
        case "Cochran Films":
            return ["Events", "Live Production", "Green Screen", "Podcast"]
        case "Course Creator Academy":
            return ["Course Creator Academy"]
        default:
            return []
        }
    }
    
    private var services: [String] {
        switch (selectedCompany, selectedCategory) {
        case ("Cochran Films", "Events"):
            return ["2 Hours", "3 Hours", "5 Hours", "8 Hours", "8 Hours with Recap"]
        case ("Cochran Films", "Live Production"):
            return ["3 Hours", "5 Hours", "8 Hours"]
        case ("Cochran Films", "Green Screen"):
            return ["Studio Rental Only", "30 Min - 1 Hour Session", "2-3 Hour Session", "4 Hour Session", "4 Hour Session with Edits"]
        case ("Cochran Films", "Podcast"):
            return ["1 Hour Podcast", "2 Hour Podcast", "3 Hour Podcast", "Shoot Only"]
        case ("Course Creator Academy", "Course Creator Academy"):
            return ["Job Shadow", "Curious Learner", "3-Month Access", "6-Month Access", "Full Year Access"]
        default:
            return []
        }
    }
    
    private func getDefaultCategory(for company: String) -> String {
        switch company {
        case "Cochran Films": return "Events"
        case "Course Creator Academy": return "Course Creator Academy"
        default: return ""
        }
    }
    
    private func getDefaultService(for category: String) -> String {
        switch category {
        case "Events": return "2 Hours"
        case "Live Production": return "3 Hours"
        case "Green Screen": return "Studio Rental Only"
        case "Podcast": return "1 Hour Podcast"
        case "Course Creator Academy": return "Job Shadow"
        default: return ""
        }
    }
    
    private var basePrice: Double {
        switch (selectedCompany, selectedCategory, selectedService) {
        // Events
        case ("Cochran Films", "Events", "2 Hours"): return 500
        case ("Cochran Films", "Events", "3 Hours"): return 750
        case ("Cochran Films", "Events", "5 Hours"): return 1250
        case ("Cochran Films", "Events", "8 Hours"): return 2000
        case ("Cochran Films", "Events", "8 Hours with Recap"): return 2200
        
        // Live Production
        case ("Cochran Films", "Live Production", "3 Hours"): return 2000
        case ("Cochran Films", "Live Production", "5 Hours"): return 3000
        case ("Cochran Films", "Live Production", "8 Hours"): return 4000
        
        // Green Screen
        case ("Cochran Films", "Green Screen", "Studio Rental Only"): return 40 // Base price for first hour
        case ("Cochran Films", "Green Screen", "30 Min - 1 Hour Session"): return 300
        case ("Cochran Films", "Green Screen", "2-3 Hour Session"): return 650
        case ("Cochran Films", "Green Screen", "4 Hour Session"): return 1000
        case ("Cochran Films", "Green Screen", "4 Hour Session with Edits"): return 1300
        
        // Podcast
        case ("Cochran Films", "Podcast", "1 Hour Podcast"): return 750
        case ("Cochran Films", "Podcast", "2 Hour Podcast"): return 1000
        case ("Cochran Films", "Podcast", "3 Hour Podcast"): return 1500
        case ("Cochran Films", "Podcast", "Shoot Only"): return 250 // Base price for first hour
        
        // Course Creator Academy
        case ("Course Creator Academy", "Course Creator Academy", "Job Shadow"): return 175
        case ("Course Creator Academy", "Course Creator Academy", "Curious Learner"): return 175
        case ("Course Creator Academy", "Course Creator Academy", "3-Month Access"): return 575
        case ("Course Creator Academy", "Course Creator Academy", "6-Month Access"): return 1050
        case ("Course Creator Academy", "Course Creator Academy", "Full Year Access"): return 2000
        
        default: return 0
        }
    }
    
    private var additionalCost: Double {
        var cost = 0.0
        
        // Raw Files Cost
        if needsRawFiles {
            cost += 300
        }
        
        // Additional Hours Cost (for applicable services)
        if selectedCategory == "Green Screen" && selectedService == "Studio Rental Only" {
            cost += Double(additionalHours) * 40 // Charge for all additional hours
        } else if selectedCategory == "Podcast" && selectedService == "Shoot Only" {
            cost += Double(additionalHours) * 250 // Charge for all additional hours
        } else if additionalHours > 0 {
            cost += Double(additionalHours) * 250 // Standard hourly rate
        }
        
        // Extra Cameras Cost (for Podcast)
        if selectedCategory == "Podcast" && extraCameras > 0 {
            let podcastHours = getPodcastHours()
            if selectedService == "Shoot Only" {
                cost += Double(extraCameras) * 100 * Double(additionalHours + 1) // $100 per camera per hour including base hour
            } else {
                cost += Double(extraCameras) * 100 * Double(podcastHours) // $100 per camera per hour
            }
        }
        
        return cost
    }
    
    private func getPodcastHours() -> Int {
        switch selectedService {
        case "1 Hour Podcast": return 1
        case "2 Hour Podcast": return 2
        case "3 Hour Podcast": return 3
        case "Shoot Only": return 1 // Base hour for shoot only
        default: return 0
        }
    }
    
    private var totalCost: Double {
        basePrice + additionalCost
    }
    
    private var showExtraCameras: Bool {
        selectedCompany == "Cochran Films" && selectedCategory == "Podcast" && selectedService != "Shoot Only"
    }
    
    private var showAdditionalHours: Bool {
        (selectedCompany == "Cochran Films" && selectedCategory == "Green Screen" && selectedService == "Studio Rental Only") ||
        (selectedCompany == "Cochran Films" && selectedCategory == "Podcast" && selectedService == "Shoot Only")
    }
    
    private func getEventDescription(_ service: String) -> String? {
        switch service {
        case "2 Hours", "3 Hours", "5 Hours", "8 Hours with Recap":
            return "Includes 60-Second Recap"
        case "8 Hours":
            return "No Edits"
        default:
            return nil
        }
    }
    
    private func getLiveProductionDescription() -> String {
        return "Up to 3 Cameras + Production Edit"
    }
    
    private func getGreenScreenDescription(_ service: String) -> String? {
        if service.contains("Edits") {
            return "Includes Edits"
        } else if service == "4 Hour Session" {
            return "No Edits"
        }
        return nil
    }
    
    private func getPodcastDescription(_ service: String) -> String? {
        return service != "Shoot Only" ? "2 Cameras + Edits" : nil
    }
    
    private func getCourseCreatorDescription(_ service: String) -> String? {
        switch service {
        case "Job Shadow":
            return "Monthly Shadow + Creative Projects"
        case "Curious Learner":
            return "1-Month Access + 2 Classes/Month"
        case "3-Month Access":
            return "3-Month Access + 2 Classes/Month"
        case "6-Month Access":
            return "6-Month Access + 2 Classes/Month"
        case "Full Year Access":
            return "365-Day Access + 6 Free Shadows"
        default:
            return nil
        }
    }
    
    private var packageDescription: String? {
        switch (selectedCompany, selectedCategory) {
        case ("Cochran Films", "Events"):
            return getEventDescription(selectedService)
        case ("Cochran Films", "Live Production"):
            return getLiveProductionDescription()
        case ("Cochran Films", "Green Screen"):
            return getGreenScreenDescription(selectedService)
        case ("Cochran Films", "Podcast"):
            return getPodcastDescription(selectedService)
        case ("Course Creator Academy", "Course Creator Academy"):
            return getCourseCreatorDescription(selectedService)
        default:
            return nil
        }
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                ScrollView(.vertical, showsIndicators: false) {
                    MainContentView(
                        selectedCompany: $selectedCompany,
                        selectedCategory: $selectedCategory,
                        selectedService: $selectedService,
                        needsRawFiles: $needsRawFiles,
                        additionalHours: $additionalHours,
                        extraCameras: $extraCameras,
                        showingContactForm: $showingContactForm,
                        invoiceViewModel: invoiceViewModel,
                        companies: companies,
                        categories: categories,
                        services: services,
                        packageDescription: packageDescription,
                        showAdditionalHours: showAdditionalHours,
                        showExtraCameras: showExtraCameras,
                        basePrice: basePrice,
                        totalCost: totalCost,
                        getPodcastHours: getPodcastHours,
                        clientName: $clientName,
                        clientEmail: $clientEmail,
                        quantity: $quantity
                    )
                }
                .background(Color.black)
                .navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .top) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text("Cost Estimator")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.black)
                }
                .sheet(isPresented: $showingContactForm) {
                    ContactView()
                }
            }

            // Add the popup overlay
            if invoiceViewModel.showCreatedPopup, 
               let urlString = invoiceViewModel.invoiceUrl,
               let url = URL(string: urlString) {
                PopupOverlay(url: url, viewModel: invoiceViewModel)
            }
        }
        .onChange(of: invoiceViewModel.shouldNavigateToInvoices) { _, newValue in
            if newValue {
                dismiss()
            }
        }
    }
}

struct MainContentView: View {
    @Binding var selectedCompany: String
    @Binding var selectedCategory: String
    @Binding var selectedService: String
    @Binding var needsRawFiles: Bool
    @Binding var additionalHours: Int
    @Binding var extraCameras: Int
    @Binding var showingContactForm: Bool
    @ObservedObject var invoiceViewModel: InvoiceViewModel
    let companies: [String]
    let categories: [String]
    let services: [String]
    let packageDescription: String?
    let showAdditionalHours: Bool
    let showExtraCameras: Bool
    let basePrice: Double
    let totalCost: Double
    let getPodcastHours: () -> Int
    @Binding var clientName: String
    @Binding var clientEmail: String
    @Binding var quantity: Int
    @State private var selectedItems: Set<String> = []
    
    var body: some View {
        VStack(spacing: 24) {
            CompanySelectionSection(
                selectedCompany: $selectedCompany,
                selectedCategory: $selectedCategory,
                selectedService: $selectedService,
                additionalHours: $additionalHours,
                extraCameras: $extraCameras,
                needsRawFiles: $needsRawFiles,
                companies: companies
            )
            
            if selectedCompany == "Cochran Films" {
                CategorySelectionSection(
                    selectedCategory: $selectedCategory,
                    selectedService: $selectedService,
                    additionalHours: $additionalHours,
                    extraCameras: $extraCameras,
                    needsRawFiles: $needsRawFiles,
                    categories: categories
                )
            }
            
            ServiceSelectionSection(
                selectedService: $selectedService,
                services: services
            )
            
            if let description = packageDescription {
                PackageDescriptionView(description: description)
            }
            
            AdditionalOptionsSection(
                selectedCompany: selectedCompany,
                selectedCategory: selectedCategory,
                needsRawFiles: $needsRawFiles,
                additionalHours: $additionalHours,
                extraCameras: $extraCameras,
                showAdditionalHours: showAdditionalHours,
                showExtraCameras: showExtraCameras,
                getPodcastHours: getPodcastHours
            )
            
            CostBreakdownSection(
                basePrice: basePrice,
                needsRawFiles: needsRawFiles,
                additionalHours: additionalHours,
                showAdditionalHours: showAdditionalHours,
                selectedCategory: selectedCategory,
                extraCameras: extraCameras,
                getPodcastHours: getPodcastHours,
                totalCost: totalCost
            )
            
            ButtonsSection(
                showingContactForm: $showingContactForm,
                selectedCompany: selectedCompany,
                selectedCategory: selectedCategory,
                selectedService: selectedService,
                totalCost: totalCost,
                invoiceViewModel: invoiceViewModel,
                clientName: $clientName,
                clientEmail: $clientEmail,
                quantity: $quantity,
                needsRawFiles: needsRawFiles,
                additionalHours: additionalHours,
                extraCameras: extraCameras,
                basePrice: basePrice,
                getPodcastHours: getPodcastHours,
                selectedItems: $selectedItems
            )
        }
        .padding(20)
        .onChange(of: selectedService) { _, _ in
            selectedItems = [selectedService]
        }
    }
}

struct CompanySelectionSection: View {
    @Binding var selectedCompany: String
    @Binding var selectedCategory: String
    @Binding var selectedService: String
    @Binding var additionalHours: Int
    @Binding var extraCameras: Int
    @Binding var needsRawFiles: Bool
    let companies: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Company")
                .font(.headline)
                .foregroundColor(.white)
            Picker("Select Company", selection: $selectedCompany) {
                ForEach(companies, id: \.self) { company in
                    Text(company)
                        .foregroundColor(company == "Course Creator Academy" ? .blue : 
                                       company == "Cochran Films" ? Color(hex: "dca54e") : .white)
                }
            }
            .onChange(of: selectedCompany) { oldValue, newValue in
                selectedCategory = getDefaultCategory(for: newValue)
                selectedService = getDefaultService(for: selectedCategory)
                additionalHours = 0
                extraCameras = 0
                if newValue == "Course Creator Academy" {
                    needsRawFiles = false
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
        }
    }
    
    private func getDefaultCategory(for company: String) -> String {
        switch company {
        case "Cochran Films": return "Events"
        case "Course Creator Academy": return "Course Creator Academy"
        default: return ""
        }
    }
    
    private func getDefaultService(for category: String) -> String {
        switch category {
        case "Events": return "2 Hours"
        case "Live Production": return "3 Hours"
        case "Green Screen": return "Studio Rental Only"
        case "Podcast": return "1 Hour Podcast"
        case "Course Creator Academy": return "Job Shadow"
        default: return ""
        }
    }
}

struct CategorySelectionSection: View {
    @Binding var selectedCategory: String
    @Binding var selectedService: String
    @Binding var additionalHours: Int
    @Binding var extraCameras: Int
    @Binding var needsRawFiles: Bool
    let categories: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category")
                .font(.headline)
                .foregroundColor(.white)
            Picker("Select Category", selection: $selectedCategory) {
                ForEach(categories, id: \.self) { category in
                    Text(category)
                }
            }
            .onChange(of: selectedCategory) { oldValue, newValue in
                selectedService = getDefaultService(for: newValue)
                additionalHours = 0
                extraCameras = 0
                needsRawFiles = false
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
        }
    }
    
    private func getDefaultService(for category: String) -> String {
        switch category {
        case "Events": return "2 Hours"
        case "Live Production": return "3 Hours"
        case "Green Screen": return "Studio Rental Only"
        case "Podcast": return "1 Hour Podcast"
        case "Course Creator Academy": return "Job Shadow"
        default: return ""
        }
    }
}

struct ServiceSelectionSection: View {
    @Binding var selectedService: String
    let services: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Service")
                .font(.headline)
                .foregroundColor(.white)
            Picker("Select Service", selection: $selectedService) {
                ForEach(services, id: \.self) { service in
                    Text(service)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
        }
    }
}

struct PackageDescriptionView: View {
    let description: String
    
    var body: some View {
        Text(description)
            .font(.subheadline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
    }
}

struct AdditionalOptionsSection: View {
    let selectedCompany: String
    let selectedCategory: String
    @Binding var needsRawFiles: Bool
    @Binding var additionalHours: Int
    @Binding var extraCameras: Int
    let showAdditionalHours: Bool
    let showExtraCameras: Bool
    let getPodcastHours: () -> Int
    
    var body: some View {
        VStack(spacing: 16) {
            if selectedCompany == "Cochran Films" {
                Toggle("Include Raw Files (+$300)", isOn: $needsRawFiles)
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .tint(.orange)
            }
            
            if showAdditionalHours {
                let hourlyRate = selectedCategory == "Green Screen" ? 40 : 250
                Stepper("Additional Hours: \(additionalHours) (+$\(hourlyRate)/hr)", value: $additionalHours, in: 0...8)
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .foregroundColor(.white)
            }
            
            if showExtraCameras {
                let podcastHours = getPodcastHours()
                Stepper("Extra Cameras: \(extraCameras) (+$100/camera/hour × \(podcastHours)hr)", value: $extraCameras, in: 0...2)
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .foregroundColor(.white)
            }
        }
    }
}

struct CostBreakdownSection: View {
    let basePrice: Double
    let needsRawFiles: Bool
    let additionalHours: Int
    let showAdditionalHours: Bool
    let selectedCategory: String
    let extraCameras: Int
    let getPodcastHours: () -> Int
    let totalCost: Double
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Cost Breakdown")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                CostRow(label: "Base Price", value: basePrice)
                if needsRawFiles {
                    CostRow(label: "Raw Files", value: 300)
                }
                if additionalHours > 0 && showAdditionalHours {
                    let hourlyRate = selectedCategory == "Green Screen" ? 40.0 : 250.0
                    CostRow(label: "Additional Hours", value: Double(additionalHours) * hourlyRate)
                }
                if extraCameras > 0 {
                    let podcastHours = getPodcastHours()
                    CostRow(label: "Extra Cameras (\(podcastHours)hr)", value: Double(extraCameras) * 100 * Double(podcastHours))
                }
                Divider()
                    .background(Color.white)
                CostRow(label: "Total Estimated Cost", value: totalCost, isTotal: true)
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
        }
    }
}

struct ButtonsSection: View {
    @Binding var showingContactForm: Bool
    let selectedCompany: String
    let selectedCategory: String
    let selectedService: String
    let totalCost: Double
    @ObservedObject var invoiceViewModel: InvoiceViewModel
    @Binding var clientName: String
    @Binding var clientEmail: String
    @Binding var quantity: Int
    let needsRawFiles: Bool
    let additionalHours: Int
    let extraCameras: Int
    let basePrice: Double
    let getPodcastHours: () -> Int
    
    @Binding var selectedItems: Set<String>
    
    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                showingContactForm = true
            }) {
                Text("Contact Us")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.init(hex: "dca54e"))
                    .cornerRadius(12)
            }
            
            if totalCost > 0 && AuthenticationManager.shared.isAuthenticated {
                Button(action: {
                    if let email = AuthenticationManager.shared.userProfile?.email {
                        // Set client information
                        clientEmail = email
                        if !AuthenticationManager.shared.localUsername.isEmpty {
                            clientName = AuthenticationManager.shared.localUsername
                        } else if let name = AuthenticationManager.shared.userProfile?.name, !name.contains("@") {
                            clientName = name
                        }
                        
                        // Create invoice immediately
                        createInvoice()
                        
                        // Clear selections after successful creation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            selectedItems.removeAll()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                        Text("Create Invoice")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.init(hex: "dca54e"))
                    .cornerRadius(12)
                }
                .disabled(invoiceViewModel.isCreatingInvoice)
            }
        }
    }
    
    private func createInvoice() {
        Task {
            if selectedCompany == "Course Creator Academy" {
                WaveService.shared.setBusinessName("Course Creator Academy LLC")
                await createCourseCreatorInvoice()
            } else {
                WaveService.shared.setBusinessName("Cochran Films")
                await createCochranFilmsInvoice()
            }
        }
    }
    
    private func createCourseCreatorInvoice() async {
        if let email = AuthenticationManager.shared.userProfile?.email {
            clientEmail = email
            if !AuthenticationManager.shared.localUsername.isEmpty {
                clientName = AuthenticationManager.shared.localUsername
            } else if let name = AuthenticationManager.shared.userProfile?.name, !name.contains("@") {
                clientName = name
            }
            
            let baseDescription = """
            \(selectedService)
            Quantity: \(quantity)
            """
            
            do {
                try await invoiceViewModel.createInvoice(
                    clientName: clientName,
                    clientEmail: clientEmail,
                    amount: totalCost / Double(quantity),
                    serviceDescription: baseDescription,
                    invoiceTitle: "CCA Education",
                    dueDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
                    notes: "",
                    quantity: quantity
                )
            } catch {
                print("Error creating Course Creator invoice: \(error.localizedDescription)")
                await MainActor.run {
                    invoiceViewModel.error = error
                    invoiceViewModel.isCreatingInvoice = false
                }
            }
        }
    }
    
    private func createCochranFilmsInvoice() async {
        if let email = AuthenticationManager.shared.userProfile?.email {
            clientEmail = email
            if !AuthenticationManager.shared.localUsername.isEmpty {
                clientName = AuthenticationManager.shared.localUsername
            } else if let name = AuthenticationManager.shared.userProfile?.name, !name.contains("@") {
                clientName = name
            }
            
            let baseDescription = """
            Service: \(selectedService)
            Additional Hours: \(additionalHours)
            Extra Cameras: \(extraCameras)
            Quantity: \(quantity)
            """
            
            do {
                if needsRawFiles {
                    try await invoiceViewModel.createInvoiceWithItems(
                        clientName: clientName,
                        clientEmail: clientEmail,
                        items: [
                            (
                                title: "\(selectedService) - \(selectedCategory)",
                                description: baseDescription,
                                amount: (basePrice + (selectedCategory == "Green Screen" ? Double(additionalHours) * 40.0 : Double(additionalHours) * 250.0) + (Double(extraCameras) * 100.0 * Double(getPodcastHours()))) / Double(quantity),
                                quantity: quantity
                            ),
                            (
                                title: "Raw Files",
                                description: "Raw video files export",
                                amount: 300.0,
                                quantity: 1
                            )
                        ],
                        dueDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
                        notes: ""
                    )
                } else {
                    try await invoiceViewModel.createInvoice(
                        clientName: clientName,
                        clientEmail: clientEmail,
                        amount: totalCost / Double(quantity),
                        serviceDescription: baseDescription,
                        invoiceTitle: "\(selectedService) - \(selectedCategory)",
                        dueDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
                        notes: "",
                        quantity: quantity
                    )
                }
            } catch {
                print("Error creating Cochran Films invoice: \(error.localizedDescription)")
                await MainActor.run {
                    invoiceViewModel.error = error
                    invoiceViewModel.isCreatingInvoice = false
                }
            }
        }
    }
}

struct CostRow: View {
    let label: String
    let value: Double
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? .headline : .subheadline)
                .foregroundColor(.white)
            Spacer()
            Text(String(format: "$%.2f", value))
                .font(isTotal ? .headline : .subheadline)
                .foregroundColor(isTotal ? .orange : .white)
        }
    }
}

#Preview {
    CostEstimatorView()
        .preferredColorScheme(.dark)
} 
