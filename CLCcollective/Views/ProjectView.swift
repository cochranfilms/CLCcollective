import SwiftUI

private enum Layout {
    static let maxWidth: CGFloat = 500
    static let cardPadding: CGFloat = 24
    static let contentSpacing: CGFloat = 20
    static let cornerRadius: CGFloat = 20
    static let buttonHeight: CGFloat = 50
}

struct ProjectView: View {
    let project: Project
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: ProjectViewModel
    @StateObject private var invoiceViewModel = InvoiceViewModel()
    @State private var isAddingTask = false
    @State private var showingDeleteAlert = false
    @State private var isEditingTask = false
    @State private var isEditingProject = false
    @State private var isAppearing = false
    
    var body: some View {
        ScrollView {
            let spacing: CGFloat = 24
            VStack(spacing: spacing) {
                // Project Header
                projectHeader
                
                // Progress Section
                progressSection
                
                // Project Details
                projectDetailsSection
                
                // Invoice Connection Section
                invoiceConnectionSection
                
                // Tasks Section
                tasksSection(project)
                
                // Action Buttons
                actionButtons
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                CustomBackButton(title: "Projects", action: { dismiss() })
            }
        }
        .alert("Delete Project", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteProject(project.id)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this project? This action cannot be undone.")
        }
        .sheet(isPresented: $viewModel.showInvoiceSelector) {
            invoiceSelectorSheet
        }
        .sheet(isPresented: $isAddingTask) {
            AddTaskView(
                isPresented: $isAddingTask,
                projectId: project.id,
                viewModel: viewModel
            )
        }
        .sheet(isPresented: $isEditingTask) {
            EditTasksView(
                isPresented: $isEditingTask,
                project: project,
                viewModel: viewModel
            )
        }
        .sheet(isPresented: $isEditingProject) {
            EditProjectView(
                isPresented: $isEditingProject,
                project: project,
                viewModel: viewModel
            )
        }
        .task {
            await viewModel.fetchProjects()
        }
    }
    
    private var projectHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(project.title)
                .font(.title)
                .bold()
                .foregroundColor(.white)
            
            Text(project.description)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private var progressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Progress")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(project.status.rawValue)
                    .font(.headline)
                    .foregroundColor(statusColor(for: project.status))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    if project.progress > 0 {
                        Rectangle()
                            .fill(statusColor(for: project.status))
                            .frame(width: geometry.size.width * project.progress, height: 8)
                            .cornerRadius(4)
                            .animation(.easeInOut, value: project.progress)
                    }
                }
            }
            .frame(height: 8)
            
            Text("\(Int(project.progress * 100))% Complete")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private var projectDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailRow(title: "Client", value: project.clientName)
            
            statusPickerRow
            
            DetailRow(title: "Due Date", value: project.dueDate.formatted(date: .long, time: .omitted))
            
            if project.invoiceId != nil {
                DetailRow(title: "Amount", value: String(format: "$%.2f", project.amount))
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private var statusPickerRow: some View {
        HStack {
            Text("Status")
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            if viewModel.isAdmin {
                Picker("Status", selection: Binding(
                    get: { project.status },
                    set: { newStatus in
                        Task {
                            await viewModel.updateProjectStatus(projectId: project.id, status: newStatus)
                        }
                    }
                )) {
                    ForEach(Project.ProjectStatus.allCases, id: \.self) { status in
                        Text(status.rawValue)
                            .tag(status)
                    }
                }
                .pickerStyle(.menu)
                .accentColor(Color(hex: "#dca54e"))
            } else {
                Text(project.status.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var invoiceConnectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Connected Invoice")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if project.invoiceId == nil {
                    Button(action: {
                        viewModel.showInvoiceSelector = true
                    }) {
                        HStack {
                            Image(systemName: "link.badge.plus")
                            Text("Connect Invoice")
                        }
                        .foregroundColor(Color(hex: "#dca54e"))
                    }
                }
            }
            
            if let invoiceId = project.invoiceId {
                HStack {
                    Text("Invoice ID: \(invoiceId)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Button(action: {
                        viewModel.showInvoiceSelector = true
                    }) {
                        Text("Change")
                            .foregroundColor(Color(hex: "#dca54e"))
                    }
                }
            } else {
                Text("No invoice connected")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                isEditingTask = true
            }) {
                HStack {
                    Image(systemName: "checklist")
                    Text("Edit Tasks")
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(hex: "#dca54e"))
                .cornerRadius(12)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Button(action: {
                isEditingProject = true
            }) {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("Edit Project")
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(hex: "#dca54e"))
                .cornerRadius(12)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Button(action: {
                showingDeleteAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete Project")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(hex: "#dca54e").opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var invoiceSelectorSheet: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button(action: {
                            viewModel.showInvoiceSelector = false
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Projects")
                            }
                            .foregroundColor(Color(hex: "#dca54e"))
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 60)
                    
                    Text("Select Invoice")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(Color(hex: "#dca54e"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 20)
                    
                    if invoiceViewModel.invoices.isEmpty {
                        emptyInvoiceView
                    } else {
                        invoiceList
                    }
                }
                .padding(.bottom, 24)
            }
            .background(invoiceSelectorBackground(geometry))
            .ignoresSafeArea()
        }
        .task {
            await invoiceViewModel.fetchInvoices()
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
    
    private var emptyInvoiceView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#dca54e").opacity(0.5))
            
            Text("No invoices available")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "#dca54e").opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
        .opacity(isAppearing ? 1 : 0)
        .offset(y: isAppearing ? 0 : 20)
    }
    
    private var invoiceList: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(invoiceViewModel.invoices.enumerated()), id: \.element.id) { index, invoice in
                invoiceRow(invoice: invoice, index: index)
            }
        }
        .padding(.horizontal)
    }
    
    private func invoiceRow(invoice: Invoice, index: Int) -> some View {
        Button(action: {
            Task {
                await viewModel.connectInvoice(projectId: project.id, invoiceId: invoice.id)
                viewModel.showInvoiceSelector = false
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(Color(hex: "#dca54e"))
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(invoice.displayTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(invoice.customerName)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text("$\(invoice.amount, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#dca54e"))
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#dca54e").opacity(0.8))
                    
                    Text(invoice.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(Color(hex: "#dca54e"))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "#dca54e").opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "#dca54e").opacity(0.3), lineWidth: 1)
            )
        }
        .opacity(isAppearing ? 1 : 0)
        .offset(y: isAppearing ? 0 : 20)
        .animation(.easeOut.delay(Double(index) * 0.1), value: isAppearing)
    }
    
    private func invoiceSelectorBackground(_ geometry: GeometryProxy) -> some View {
        Image("background_image")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(Color.black.opacity(0.85))
            .ignoresSafeArea()
    }
    
    private func statusColor(for status: Project.ProjectStatus) -> Color {
        switch status {
        case .notStarted:
            return .gray
        case .inProgress:
            return Color(hex: "#dca54e") // Brand gold
        case .completed:
            return .green
        case .onHold:
            return .orange
        case .cancelled:
            return .red
        }
    }
    
    private func progressForStatus(_ status: Project.ProjectStatus) -> CGFloat {
        switch status {
        case .notStarted:
            return 0.0
        case .inProgress:
            return 0.5
        case .completed:
            return 1.0
        case .onHold:
            return 0.25
        case .cancelled:
            return 0.0
        @unknown default:
            return 0.0
        }
    }
    
    private func tasksSection(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tasks")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: { isAddingTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color(hex: "#dca54e"))
                }
            }
            
            ForEach(project.tasks) { task in
                if viewModel.isAdmin {
                    AdminTaskRow(task: task, projectId: project.id, viewModel: viewModel)
                } else {
                    ClientTaskRow(task: task)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

struct ClientTaskRow: View {
    let task: ProjectTask
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? Color(hex: "#dca54e") : .gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}

#Preview {
    ProjectView(project: Project(
        id: "1",
        title: "Sample Project",
        description: "This is a sample project",
        status: .notStarted,
        clientName: "John Doe",
        clientEmail: "john@example.com",
        amount: 1000.0,
        invoiceId: "inv_123",
        clientId: "preview_user_id",
        isArchived: false,
        createdAt: Date(),
        updatedAt: Date(),
        dueDate: Date().addingTimeInterval(7 * 24 * 60 * 60), // 7 days from now
        progress: 0.6,
        tasks: [
            ProjectTask(
                title: "Task 1",
                description: "Description 1",
                isCompleted: true,
                completedAt: Date()
            ),
            ProjectTask(
                title: "Task 2",
                description: "Description 2"
            )
        ]
    ))
} 