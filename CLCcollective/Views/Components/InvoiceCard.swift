import SwiftUI

struct InvoiceCard: View {
    let invoice: Invoice
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(invoice.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(invoice.customerName)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(invoice.status)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#dca54e").opacity(0.2))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "#dca54e"), lineWidth: 1)
                    )
            }
            
            // Details
            HStack {
                // Amount
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(Color(hex: "#dca54e"))
                    Text(String(format: "$%.2f", invoice.amount))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Due Date
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .foregroundColor(Color(hex: "#dca54e"))
                    if let dueDate = invoice.dueDate {
                        Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#dca54e").opacity(0.3), lineWidth: 1)
        )
    }
} 