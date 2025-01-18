import SwiftUI

struct SelectInvoiceView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = InvoiceViewModel()
    @State private var isAppearing = false
    @State private var showingDeleteConfirmation = false
    @State private var invoiceToDelete: Invoice?
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""
    private let brandGold = Color(hex: "#dca54e")
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("Your Invoices")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(brandGold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 60)
                        .padding(.horizontal)
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 30)
                    
                    // Content
                    VStack(spacing: 16) {
                        if viewModel.isLoadingInvoices {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: brandGold))
                                .scaleEffect(1.5)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 50)
                        } else if viewModel.invoices.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(brandGold.opacity(0.5))
                                
                                Text("No invoices found")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(brandGold.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        } else {
                            ForEach(viewModel.invoices, id: \.uniqueId) { invoice in
                                InvoiceRowView(
                                    invoice: invoice,
                                    onDelete: {
                                        invoiceToDelete = invoice
                                        showingDeleteConfirmation = true
                                    },
                                    onOpen: {
                                        // Handle invoice selection
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .background(
                Image("background_image")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(Color.black.opacity(0.85))
                    .ignoresSafeArea()
            )
            .ignoresSafeArea()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                CustomBackButton(title: "Back", action: { dismiss() })
            }
        }
        .task {
            withAnimation(.easeOut(duration: 0.8)) {
                isAppearing = true
            }
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
    SelectInvoiceView()
        .preferredColorScheme(.dark)
} 