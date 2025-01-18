import SwiftUI

private enum Layout {
    static let maxWidth: CGFloat = 500
    static let cardPadding: CGFloat = 24
    static let contentSpacing: CGFloat = 20
    static let cornerRadius: CGFloat = 20
    static let buttonHeight: CGFloat = 50
}

struct ProjectsListView: View {
    @EnvironmentObject var viewModel: ProjectViewModel
    @State private var showingCreateProject = false
    @State private var isAppearing = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: Layout.contentSpacing) {
                // Create Project Button
                Button(action: {
                    showingCreateProject = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Project")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.buttonHeight)
                    .background(Color(hex: "#dca54e"))
                    .cornerRadius(Layout.cornerRadius)
                }
                .padding(.horizontal)
                
                // Projects List
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.projects) { project in
                        NavigationLink(destination: ProjectView(project: project)) {
                            ProjectCard(project: project)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Projects")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                CustomBackButton(title: "Profile", action: { dismiss() })
            }
        }
        .sheet(isPresented: $showingCreateProject) {
            CreateProjectView(viewModel: viewModel)
        }
        .task {
            await viewModel.fetchProjects()
        }
    }
}

#Preview {
    NavigationView {
        ProjectsListView()
            .environmentObject(ProjectViewModel())
    }
} 