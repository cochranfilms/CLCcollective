import Foundation
import SwiftUI

class InvoiceService: ObservableObject {
    @Published var invoices: [Invoice] = []
    private let projectService = ProjectService()
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "invoices"),
           let savedInvoices = try? JSONDecoder().decode([Invoice].self, from: data) {
            self.invoices = savedInvoices
        }
    }
    
    func deleteInvoice(_ invoiceId: String) {
        // Find any projects associated with this invoice
        let associatedProjects = projectService.projects.filter { $0.invoiceId == invoiceId }
        
        // Update each project to remove the invoice reference
        for var project in associatedProjects {
            project.invoiceId = nil
            project.updatedAt = Date()
            projectService.updateProject(project)
        }
        
        // Delete the invoice
        invoices.removeAll(where: { $0.id == invoiceId })
        saveInvoices()
    }
    
    private func saveInvoices() {
        if let encoded = try? JSONEncoder().encode(invoices) {
            UserDefaults.standard.set(encoded, forKey: "invoices")
        }
    }
    
    // Add other invoice-related methods here...
} 