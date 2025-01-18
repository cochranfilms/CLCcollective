import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    private let brandGold = Color(hex: "#dca54e")
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Privacy Policy")
                            .font(.title)
                            .foregroundColor(brandGold)
                        
                        Text("Last updated: \(Date.now.formatted(date: .long, time: .omitted))")
                            .foregroundColor(.gray)
                        
                        policySection(title: "Information We Collect",
                                    content: "We collect information that you provide directly to us, including name, email address, and any other information you choose to provide. We also automatically collect certain information about your device when you use our services.")
                        
                        policySection(title: "How We Use Your Information",
                                    content: "We use the information we collect to provide, maintain, and improve our services, communicate with you, and comply with legal obligations.")
                        
                        policySection(title: "Information Sharing",
                                    content: "We do not share your personal information with third parties except as described in this privacy policy or with your consent.")
                        
                        policySection(title: "Data Security",
                                    content: "We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.")
                        
                        policySection(title: "Your Rights",
                                    content: "You have the right to access, correct, or delete your personal information. You can also object to or restrict certain processing of your information.")
                        
                        policySection(title: "Changes to This Policy",
                                    content: "We may update this privacy policy from time to time. We will notify you of any changes by posting the new privacy policy on this page.")
                        
                        policySection(title: "Contact Us",
                                    content: "If you have any questions about this privacy policy, please contact us at privacy@cochranfilms.com")
                    }
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
    
    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(brandGold)
            
            Text(content)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
    }
} 