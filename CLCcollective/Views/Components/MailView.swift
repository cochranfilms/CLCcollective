import SwiftUI
import MessageUI

struct MailView: UIViewControllerRepresentable {
    @Binding var isShowing: Bool
    var result: ((Result<MFMailComposeResult, Error>) -> Void)?
    var subject: String
    var toRecipients: [String]
    var messageBody: String
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        mailComposer.setSubject(subject)
        mailComposer.setToRecipients(toRecipients)
        mailComposer.setMessageBody(messageBody, isHTML: false)
        return mailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isShowing: $isShowing, result: result)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isShowing: Bool
        var result: ((Result<MFMailComposeResult, Error>) -> Void)?
        
        init(isShowing: Binding<Bool>, result: ((Result<MFMailComposeResult, Error>) -> Void)?) {
            self._isShowing = isShowing
            self.result = result
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                self.result?(.failure(error))
            } else {
                self.result?(.success(result))
            }
            isShowing = false
            controller.dismiss(animated: true)
        }
    }
} 