import SwiftUI
import MessageUI

class ContactViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var phone = ""
    @Published var subject = ""
    @Published var message = ""
    @Published var isSending = false
    @Published var showSuccessMessage = false
    @Published var error: String?
    
    var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && isValidEmail(email) && !message.isEmpty
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func validateForm() -> Bool {
        isFormValid
    }
    
    @MainActor
    func sendEmail(toEmail: String, isCCA: Bool) async {
        guard validateForm() else { return }
        
        isSending = true
        error = nil
        
        do {
            let success = try await EmailService.shared.sendEmail(
                name: name,
                email: email,
                phone: phone,
                subject: subject,
                message: message,
                toEmail: toEmail,
                isCCA: isCCA
            )
            
            if success {
                showSuccessMessage = true
                ActivityManager.shared.logContactForm(description: "Sent email inquiry to \(toEmail): \(subject)")
                // Clear form
                name = ""
                email = ""
                phone = ""
                subject = ""
                message = ""
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isSending = false
    }
    
    @MainActor
    func sendToCochranFilms() async {
        await sendEmail(toEmail: "info@cochranfilms.com", isCCA: false)
    }
    
    @MainActor
    func sendToCCA() async {
        await sendEmail(toEmail: "info@coursecreatoracademy.org", isCCA: true)
    }
    
    func callPhone() {
        if let url = URL(string: "tel://4704202169") {
            UIApplication.shared.open(url)
        }
    }
    
    func sendText() {
        if let url = URL(string: "sms:4704202169") {
            UIApplication.shared.open(url)
        }
    }
} 
