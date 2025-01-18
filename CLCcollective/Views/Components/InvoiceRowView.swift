import SwiftUI

struct InvoiceRowView: View {
    let invoice: Invoice
    let onDelete: () -> Void
    let onOpen: () -> Void
    @State private var isEditingTitle = false
    @State private var editedTitle: String = ""
    @State private var displayTitle: String
    
    init(invoice: Invoice, onDelete: @escaping () -> Void, onOpen: @escaping () -> Void) {
        self.invoice = invoice
        self.onDelete = onDelete
        self.onOpen = onOpen
        self._displayTitle = State(initialValue: invoice.displayTitle)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if isEditingTitle {
                    TextField("Invoice Title", text: $editedTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            UserDefaults.standard.set(editedTitle, forKey: "invoice_display_title_\(invoice.id)")
                            displayTitle = editedTitle
                            isEditingTitle = false
                        }
                } else {
                    Text(displayTitle)
                        .font(.headline)
                }
                
                Spacer()
                
                Button(action: {
                    if !isEditingTitle {
                        editedTitle = displayTitle
                    }
                    isEditingTitle.toggle()
                }) {
                    Image(systemName: isEditingTitle ? "checkmark.circle.fill" : "pencil.circle")
                        .foregroundColor(.brandGold)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            Text(invoice.customerName)
                .foregroundColor(.gray)
            Text("$\(invoice.amount, specifier: "%.2f")")
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
    }
} 