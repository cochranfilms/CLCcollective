import Foundation
import SwiftUI

@MainActor
class InvoiceViewModel: ObservableObject {
    @Published var isCreatingInvoice = false
    @Published var invoiceUrl: String?
    @Published var error: Error?
    @Published var debugLog = ""
    @Published var invoices: [Invoice] = []
    @Published var isLoadingInvoices = false
    @Published var showCreatedPopup = false
    @Published var shouldNavigateToInvoices = false
    @Published var currentInvoiceUrl: String?
    
    private let waveService = WaveService.shared
    private let authManager = AuthenticationManager.shared
    private let projectViewModel = ProjectViewModel()
    
    func createInvoice(clientName: String, clientEmail: String, amount: Double, serviceDescription: String, invoiceTitle: String, dueDate: Date, notes: String, quantity: Int) async throws {
        await MainActor.run {
            isCreatingInvoice = true
            debugLog = ""
            invoiceUrl = nil
            currentInvoiceUrl = nil
            showCreatedPopup = false
            shouldNavigateToInvoices = false
        }
        print("Starting invoice creation...")
        
        return try await withCheckedThrowingContinuation { continuation in
            WaveService.shared.createInvoice(
                clientName: clientName,
                clientEmail: clientEmail,
                amount: amount,
                serviceDescription: serviceDescription,
                invoiceTitle: invoiceTitle.contains("Course Creator") || 
                             invoiceTitle.contains("CCA") || 
                             invoiceTitle.contains("Course Creator Academy LLC") ? "CCA Education" : invoiceTitle,
                dueDate: dueDate,
                notes: notes,
                quantity: quantity
            ) { [weak self] result in
                Task { @MainActor in
                    guard let self = self else {
                        continuation.resume(throwing: NSError(domain: "InvoiceError", code: -1, userInfo: [NSLocalizedDescriptionKey: "View model was deallocated"]))
                        return
                    }
                    
                    switch result {
                    case .success(let response):
                        let (url, invoiceId) = response
                        
                        // Update UI state in a single animation block
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.invoiceUrl = url
                            self.currentInvoiceUrl = url
                            self.showCreatedPopup = true
                            self.isCreatingInvoice = false
                        }
                        
                        // Create a project from the invoice
                        let invoice = Invoice(
                            id: invoiceId,
                            title: invoiceTitle,
                            viewUrl: url,
                            createdAt: Date(),
                            amount: amount,
                            status: "DRAFT",
                            customerName: clientName,
                            customerEmail: clientEmail,
                            dueDate: dueDate,
                            currency: "USD",
                            memo: notes
                        )
                        
                        // Create project and log activity
                        Task {
                            await self.projectViewModel.createProject(from: invoice)
                            ActivityManager.shared.logInvoiceCreated(title: invoiceTitle, amount: amount)
                            NotificationCenter.default.post(name: .invoiceCreated, object: nil)
                            
                            // Fetch invoices after project creation
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                            await self.fetchInvoices()
                        }
                        
                        continuation.resume(returning: ())
                        
                    case .failure(let error):
                        withAnimation {
                            self.error = error
                            self.isCreatingInvoice = false
                        }
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    func handlePayNow() {
        print("Handling Pay Now with URL: \(currentInvoiceUrl ?? "nil")")
        // Keep the popup visible until explicitly dismissed by the sheet
        showCreatedPopup = false
        shouldNavigateToInvoices = false
    }
    
    func handlePayLater() {
        withAnimation {
            showCreatedPopup = false
            shouldNavigateToInvoices = true
            currentInvoiceUrl = nil
        }
        
        // Post notification to switch to billing tab
        NotificationCenter.default.post(name: .switchToBillingTab, object: nil)
        
        // Ensure we refresh the invoices list
        Task {
            await fetchInvoices()
        }
    }
    
    @MainActor
    func fetchInvoices() async {
        isLoadingInvoices = true
        error = nil
        
        do {
            // Get the current user's email
            let userEmail = authManager.userProfile?.email?.lowercased()
            let isAdmin = userEmail == "info@cochranfilms.com"
            
            // For admin, fetch all invoices by passing nil as userEmail
            let allInvoices = try await waveService.fetchInvoices(forUserEmail: isAdmin ? nil : userEmail)
            withAnimation(.easeInOut(duration: 0.2)) {
                self.invoices = allInvoices
            }
        } catch {
            self.error = error
        }
        
        isLoadingInvoices = false
        
        // Notify that invoices have been refreshed
        NotificationCenter.default.post(name: .invoicesRefreshed, object: nil, userInfo: nil)
        
        // Remove duplicates based on id
        let uniqueInvoices = Array(Dictionary(grouping: invoices, by: { $0.id }).values.map { $0.first! })
        invoices = uniqueInvoices.sorted { $0.createdAt > $1.createdAt }
    }
    
    @MainActor
    func deleteInvoice(_ invoice: Invoice) async throws {
        // Delete the invoice from Wave
        try await WaveService.shared.deleteInvoice(invoiceId: invoice.id)
        
        // Remove from local array
        withAnimation {
            invoices.removeAll { $0.id == invoice.id }
        }
        
        // Disconnect the invoice from any connected projects and refresh projects
        await projectViewModel.disconnectInvoice(invoiceId: invoice.id)
        await projectViewModel.fetchProjects()
        
        // Log the activity
        ActivityManager.shared.logProjectUpdate(
            title: "Invoice Deleted",
            description: "Invoice '\(invoice.displayTitle)' was deleted"
        )
        
        // Post notification to refresh dashboard
        NotificationCenter.default.post(name: .refreshDashboard, object: nil)
    }
    
    func createInvoiceWithItems(
        clientName: String,
        clientEmail: String,
        items: [(title: String, description: String, amount: Double, quantity: Int)],
        dueDate: Date,
        notes: String
    ) async throws {
        await MainActor.run {
            isCreatingInvoice = true
            debugLog = ""
            invoiceUrl = nil
            currentInvoiceUrl = nil
            showCreatedPopup = false
            shouldNavigateToInvoices = false
        }
        print("Starting multi-item invoice creation...")
        
        return try await withCheckedThrowingContinuation { continuation in
            print("Calling Wave service to create invoice with multiple items...")
            WaveService.shared.createInvoiceWithItems(
                clientName: clientName,
                clientEmail: clientEmail,
                items: items,
                dueDate: dueDate,
                notes: notes
            ) { [weak self] result in
                Task { @MainActor in
                    guard let self = self else {
                        continuation.resume(throwing: NSError(domain: "InvoiceError", code: -1, userInfo: [NSLocalizedDescriptionKey: "View model was deallocated"]))
                        return
                    }
                    
                    switch result {
                    case .success(let response):
                        let (url, invoiceId) = response
                        
                        // Update UI state in a single animation block
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.invoiceUrl = url
                            self.currentInvoiceUrl = url
                            self.showCreatedPopup = true
                            self.isCreatingInvoice = false
                        }
                        
                        // Create a project from the invoice
                        let totalAmount = items.reduce(0.0) { $0 + ($1.amount * Double($1.quantity)) }
                        let title = if items[0].title.contains("Course Creator") || 
                                      items[0].title.contains("CCA") || 
                                      items[0].title.contains("Course Creator Academy") ||
                                      items[0].title.contains("Course Creator Academy LLC") {
                            "CCA Education"
                        } else {
                            items[0].title
                        }
                        let invoice = Invoice(
                            id: invoiceId,
                            title: title,
                            viewUrl: url,
                            createdAt: Date(),
                            amount: totalAmount,
                            status: "DRAFT",
                            customerName: clientName,
                            customerEmail: clientEmail,
                            dueDate: dueDate,
                            currency: "USD",
                            memo: notes
                        )
                        
                        // Create project and log activity
                        Task {
                            await self.projectViewModel.createProject(from: invoice)
                            print("Project created successfully")
                            
                            // Log the activity
                            ActivityManager.shared.logInvoiceCreated(title: items[0].title, amount: totalAmount)
                            
                            // Post notification for invoice creation
                            NotificationCenter.default.post(name: .invoiceCreated, object: nil)
                            
                            // Fetch invoices after project creation
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                            await self.fetchInvoices()
                        }
                        
                        continuation.resume(returning: ())
                        
                    case .failure(let error):
                        withAnimation {
                            self.error = error
                            self.isCreatingInvoice = false
                        }
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    @MainActor
    func updateInvoiceTitle(_ invoice: Invoice, newTitle: String) {
        // Update the invoice with the new title
        let updatedInvoice = invoice.withUpdatedDisplayTitle(newTitle)
        
        // Update the local array to trigger UI refresh
        if let index = invoices.firstIndex(where: { $0.id == invoice.id }) {
            invoices[index] = updatedInvoice
        }
        
        // Log the activity
        ActivityManager.shared.logProjectUpdate(
            title: "Invoice Title Updated",
            description: "Invoice title was updated to '\(newTitle)'"
        )
        
        // Post notification to refresh dashboard
        NotificationCenter.default.post(name: .refreshDashboard, object: nil)
    }
} 
