import SwiftUI

struct InvoiceList: View {
    let invoices: [Invoice]
    let onDelete: (Invoice) -> Void
    let onOpen: (Invoice) -> Void
    
    var body: some View {
        ForEach(invoices, id: \.uniqueId) { invoice in
            InvoiceRowView(
                invoice: invoice,
                onDelete: { onDelete(invoice) },
                onOpen: { onOpen(invoice) }
            )
        }
    }
}

#Preview {
    InvoiceList(
        invoices: [
            // Add sample invoice for preview
            Invoice(
                id: "preview",
                title: "Sample Invoice",
                viewUrl: "https://example.com",
                createdAt: Date(),
                amount: 1000.0,
                status: "DRAFT",
                customerName: "John Doe",
                customerEmail: "john@example.com",
                currency: "USD"
            )
        ],
        onDelete: { _ in },
        onOpen: { _ in }
    )
} 