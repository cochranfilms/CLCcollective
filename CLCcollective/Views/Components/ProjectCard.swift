import SwiftUI

struct ProjectCard: View {
    let project: Project
    @EnvironmentObject var viewModel: ProjectViewModel
    private let brandGold = Color(hex: "#dca54e")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(project.status.rawValue)
                        .font(.subheadline)
                        .foregroundColor(brandGold)
                }
                
                Spacer()
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(project.progress * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width, height: 4)
                            .opacity(0.3)
                            .foregroundColor(.gray)
                        
                        Rectangle()
                            .frame(width: geometry.size.width * project.progress, height: 4)
                            .foregroundColor(brandGold)
                    }
                    .cornerRadius(2)
                }
            }
            .frame(height: 24)
            
            // Client Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.clientName)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Text(project.clientEmail)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(project.dueDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(brandGold.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ProjectCard(project: Project(
        id: "1",
        title: "Sample Project",
        description: "This is a sample project",
        status: .inProgress,
        clientName: "John Doe",
        clientEmail: "john@example.com",
        amount: 1000.0,
        invoiceId: nil,
        clientId: "client123",
        isArchived: false,
        createdAt: Date(),
        updatedAt: Date(),
        dueDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
        progress: 0.6,
        tasks: []
    ))
    .environmentObject(ProjectViewModel())
    .padding()
    .background(Color.black)
} 