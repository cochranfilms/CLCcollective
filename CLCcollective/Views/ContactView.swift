import SwiftUI

struct ContactView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ContactViewModel()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var keyboardHeight: CGFloat = 0
    
    private let brandGold = Color(hex: "#dca54e")
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Contact Form
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Get in Touch")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        Text("Fill out the form below and we'll get back to you as soon as possible.")
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .foregroundColor(brandGold)
                                .font(.subheadline)
                            TextField("", text: $viewModel.name)
                                .placeholder(when: viewModel.name.isEmpty) {
                                    Text("Enter your name")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 16)
                                }
                                .textFieldStyle(CustomTextFieldStyle())
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .foregroundColor(brandGold)
                                .font(.subheadline)
                            TextField("", text: $viewModel.email)
                                .placeholder(when: viewModel.email.isEmpty) {
                                    Text("Enter your email")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 16)
                                }
                                .textFieldStyle(CustomTextFieldStyle())
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone")
                                .foregroundColor(brandGold)
                                .font(.subheadline)
                            TextField("", text: $viewModel.phone)
                                .placeholder(when: viewModel.phone.isEmpty) {
                                    Text("Enter your phone number")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 16)
                                }
                                .textFieldStyle(CustomTextFieldStyle())
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                                .keyboardType(.phonePad)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Subject")
                                .foregroundColor(brandGold)
                                .font(.subheadline)
                            TextField("", text: $viewModel.subject)
                                .placeholder(when: viewModel.subject.isEmpty) {
                                    Text("Enter subject")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 16)
                                }
                                .textFieldStyle(CustomTextFieldStyle())
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message")
                                .foregroundColor(brandGold)
                                .font(.subheadline)
                            ZStack(alignment: .topLeading) {
                                if viewModel.message.isEmpty {
                                    Text("Enter your message")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                }
                                TextEditor(text: $viewModel.message)
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .frame(height: 150)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                                    .textInputAutocapitalization(.sentences)
                                    .autocorrectionDisabled()
                            }
                            .frame(height: 150)
                        }
                        .padding(.bottom, 16)
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(brandGold, lineWidth: 1)
                    )
                    
                    // Submit Buttons
                    HStack(spacing: 16) {
                        // Cochran Films Button (Gold)
                        Button(action: {
                            Task {
                                await viewModel.sendToCochranFilms()
                            }
                        }) {
                            HStack {
                                if viewModel.isSending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .padding(.trailing, 8)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .padding(.trailing, 4)
                                }
                                Text(viewModel.isSending ? "Sending..." : "Send to CF")
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(brandGold)
                            .cornerRadius(10)
                        }
                        .disabled(!viewModel.isFormValid || viewModel.isSending)
                        .opacity(viewModel.isFormValid && !viewModel.isSending ? 1.0 : 0.6)
                        
                        // Course Creator Academy Button (Blue)
                        Button(action: {
                            Task {
                                await viewModel.sendToCCA()
                            }
                        }) {
                            HStack {
                                if viewModel.isSending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.trailing, 8)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .padding(.trailing, 4)
                                }
                                Text(viewModel.isSending ? "Sending..." : "Send to CCA")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        .disabled(!viewModel.isFormValid || viewModel.isSending)
                        .opacity(viewModel.isFormValid && !viewModel.isSending ? 1.0 : 0.6)
                    }
                    .padding(.vertical)
                    
                    // Alternative Contact Methods
                    VStack(spacing: 16) {
                        Text("Other Ways to Connect")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 20) {
                            ContactMethodButton(
                                icon: "phone.fill",
                                text: "Call Us",
                                action: { viewModel.callPhone() }
                            )
                            
                            ContactMethodButton(
                                icon: "message.fill",
                                text: "Text",
                                action: { viewModel.sendText() }
                            )
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(brandGold, lineWidth: 1)
                    )
                }
                .padding()
                .padding(.bottom, keyboardHeight)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(brandGold)
                    }
                }
            }
            .onAppear {
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                        keyboardHeight = keyboardFrame.height
                    }
                }
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    keyboardHeight = 0
                }
            }
            .gesture(
                TapGesture()
                    .onEnded { _ in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
            )
            .alert(isPresented: $viewModel.showSuccessMessage) {
                Alert(
                    title: Text("Success"),
                    message: Text("Your message has been sent successfully. We'll get back to you soon."),
                    dismissButton: .default(Text("OK")) {
                        dismiss()
                    }
                )
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK", role: .cancel) {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
        }
    }
}

struct ContactMethodButton: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#dca54e"))
                Text(text)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#dca54e"), lineWidth: 1)
            )
        }
    }
}

#Preview {
    ContactView()
        .preferredColorScheme(.dark)
} 