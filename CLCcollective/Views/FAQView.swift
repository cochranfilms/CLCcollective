import SwiftUI

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct FAQView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isAppearing = false
    private let brandGold = Color(hex: "#dca54e")
    
    private let faqs = [
        FAQItem(
            question: "What types of media production services do you offer?",
            answer: "Cochran Films specializes in professional video production, including brand documentaries, promotional videos, event coverage, commercials, and creative storytelling projects tailored for businesses, entrepreneurs, and diverse clients in Atlanta and beyond."
        ),
        FAQItem(
            question: "How do I get a quote for my project?",
            answer: "You can receive a personalized quote by visiting the pricing page on our website. Select your desired service and generate an invoice directly. For customized projects, reach out to our team for a consultation."
        ),
        FAQItem(
            question: "What is included in your production packages?",
            answer: "Our packages typically include pre-production planning, filming with professional equipment, post-production editing, and final delivery of high-quality video files. Additional services such as scripting, voiceovers, and multi-location shoots can be added."
        ),
        FAQItem(
            question: "Do you offer custom media production solutions for unique projects?",
            answer: "Absolutely! We understand that every brand has a unique story. Whether you need a creative documentary, a cinematic brand story, or a social media campaign, we can tailor a package that fits your vision and goals."
        ),
        FAQItem(
            question: "How long does it take to complete a project?",
            answer: "Project timelines vary depending on the complexity and scope. On average, smaller projects can take 2-4 weeks from planning to final delivery, while larger productions may take longer. We provide timeline estimates during the initial consultation."
        ),
        FAQItem(
            question: "Can I be involved in the creative process?",
            answer: "Yes! We encourage collaboration. Our team works closely with you during the planning phase to ensure your vision is fully captured. You'll have the opportunity to review drafts and provide feedback during editing stages."
        ),
        FAQItem(
            question: "Do you offer on-location filming outside of Atlanta?",
            answer: "While Cochran Films is based in Atlanta, we are available for travel to accommodate projects across various locations. Additional travel fees may apply depending on the distance and requirements."
        ),
        FAQItem(
            question: "What equipment do you use for filming?",
            answer: "We use professional-grade cameras, lenses, lighting, and audio equipment to ensure cinematic quality results. Our team stays up-to-date with the latest technology to provide the highest production standards."
        ),
        FAQItem(
            question: "How do I prepare for a shoot?",
            answer: "We guide you through the preparation process, including wardrobe suggestions, shot list planning, and location coordination. Our goal is to ensure a smooth and productive shoot day."
        ),
        FAQItem(
            question: "Why choose Cochran Films for my media production needs?",
            answer: "With years of expertise and a passion for storytelling, Cochran Films delivers not just videos but powerful visual narratives that connect with audiences. Our commitment to quality, creativity, and professionalism sets us apart in the Atlanta media production industry."
        ),
        FAQItem(
            question: "How do I create an invoice?",
            answer: "To create an invoice, navigate to the Invoices section and tap the '+' button. Fill in the required details such as client information, services, and amounts. You can preview the invoice before sending it to your client."
        ),
        FAQItem(
            question: "How do I track project progress?",
            answer: "Each project has a progress bar that can be updated as tasks are completed. You can also view detailed project statistics and completed tasks in your profile dashboard."
        ),
        FAQItem(
            question: "Can I customize my profile?",
            answer: "Yes! You can customize your profile by adding a profile picture and setting your display name. These options are available in your profile settings."
        ),
        FAQItem(
            question: "How do I manage tasks?",
            answer: "Tasks can be created and managed within each project. You can mark tasks as complete, set priorities, and track their progress. Completed tasks are automatically archived and viewable in the Completed Tasks section."
        ),
        FAQItem(
            question: "What payment methods are accepted?",
            answer: "We currently support major credit cards and bank transfers through our secure payment processing system. All transactions are encrypted and processed securely."
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("FAQ")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(brandGold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 60)
                        .padding(.horizontal)
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 20)
                    
                    // FAQ Items
                    VStack(spacing: 16) {
                        ForEach(Array(faqs.enumerated()), id: \.element.id) { index, faq in
                            FAQItemView(faq: faq)
                                .opacity(isAppearing ? 1 : 0)
                                .offset(y: isAppearing ? 0 : 20)
                                .animation(.easeOut.delay(Double(index) * 0.1), value: isAppearing)
                        }
                    }
                    .padding(.horizontal)
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
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CustomBackButton(title: "Profile", action: { dismiss() })
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAppearing = true
            }
        }
        .onDisappear {
            isAppearing = false
        }
    }
}

struct FAQItemView: View {
    let faq: FAQItem
    @State private var isExpanded = false
    private let brandGold = Color(hex: "#dca54e")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(faq.question)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(brandGold)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            
            if isExpanded {
                Text(faq.answer)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(brandGold.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationView {
        FAQView()
    }
} 