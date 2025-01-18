import SwiftUI

struct PopupOverlay: View {
    let url: URL
    @ObservedObject var viewModel: InvoiceViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
            
            InvoiceCreatedPopup(invoiceUrl: url.absoluteString, viewModel: viewModel)
                .transition(.scale.combined(with: .opacity))
        }
        .zIndex(1) // Ensure popup appears on top
        .onChange(of: viewModel.shouldNavigateToInvoices) { _, shouldNavigate in
            if shouldNavigate {
                dismiss()
            }
        }
    }
} 