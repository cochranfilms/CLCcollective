import SwiftUI
import Auth0
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var activityManager = ActivityManager.shared
    @StateObject private var viewModel = ProfileViewModel()
    
    // Local state
    @State private var selectedItem: PhotosPickerItem?
    @State private var isEditingUsername = false
    @State private var tempUsername = ""
    @State private var showingPasswordReset = false
    @State private var showingPrivacyPolicy = false
    @State private var showingClearConfirmation = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let brandGold = Color(hex: "#dca54e")
    private let brandGoldLight = Color(hex: "#dca54e").opacity(0.8)
    private let brandGoldDark = Color(hex: "#dca54e").opacity(0.6)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: brandGold))
                        .scaleEffect(1.5)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Profile Header
                            profileHeader
                            
                            // Stats Section
                            statsSection
                            
                            // Recent Activity
                            recentActivitySection
                            
                            // Account Settings
                            accountSettingsSection
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(brandGold)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        authManager.logout()
                        dismiss()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(brandGold)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Reset Password", isPresented: $showingPasswordReset) {
                Button("Cancel", role: .cancel) { }
                Button("Send Reset Email") {
                    Task {
                        await resetPassword()
                    }
                }
            } message: {
                Text("A password reset email will be sent to your registered email address.")
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .task {
                await loadInitialData()
            }
            .onDisappear {
                viewModel.stopPeriodicRefresh()
            }
            .onReceive(NotificationCenter.default.publisher(for: .invoicesRefreshed)) { _ in
                Task {
                    await refreshData()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .refreshDashboard)) { _ in
                Task {
                    await refreshData()
                }
            }
        }
    }
    
    private func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load all data concurrently
            async let profileImage = authManager.loadProfileImage()
            async let projects = projectViewModel.fetchProjects()
            async let stats = viewModel.refreshStatistics()
            
            // Wait for all operations to complete
            try await (profileImage, projects, stats)
            
            // Start periodic refresh after initial load
            viewModel.startPeriodicRefresh()
        } catch {
            showError = true
            errorMessage = "Failed to load profile data: \(error.localizedDescription)"
        }
    }
    
    private func refreshData() async {
        do {
            async let stats = viewModel.refreshStatistics()
            async let projects = projectViewModel.fetchProjects()
            try await (stats, projects)
        } catch {
            showError = true
            errorMessage = "Failed to refresh data: \(error.localizedDescription)"
        }
    }
    
    private func resetPassword() async {
        do {
            try await viewModel.resetPassword(email: authManager.userProfile?.email ?? "")
        } catch {
            showError = true
            errorMessage = "Failed to send reset password email: \(error.localizedDescription)"
        }
    }
    
    private func handleImageSelection() async {
        guard let selectedItem = selectedItem else { return }
        
        do {
            if let data = try await selectedItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                // Upload image to Cloudinary
                await authManager.uploadProfileImage(uiImage)
                // Log the activity
                await MainActor.run {
                    activityManager.logProfileUpdate(description: "Profile picture updated")
                }
            }
        } catch {
            await MainActor.run {
                showError = true
                errorMessage = "Failed to update profile image: \(error.localizedDescription)"
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 24) {
            sectionHeader("Profile Dashboard")
            
            VStack(spacing: 16) {
                // Profile Image with PhotosPicker
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    if let profileImage = authManager.profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(brandGold, lineWidth: 2)
                            )
                            .overlay(
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(brandGoldLight)
                                    .font(.system(size: 24))
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                                    .offset(x: 35, y: 35)
                            )
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(brandGold)
                            .overlay(
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(brandGoldLight)
                                    .font(.system(size: 24))
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                                    .offset(x: 35, y: 35)
                            )
                    }
                }
                .onChange(of: selectedItem) { _, newValue in
                    if let newValue {
                        Task {
                            await handleImageSelection()
                        }
                    }
                }
                
                // Name and Title
                VStack(spacing: 8) {
                    Text(authManager.localUsername.isEmpty ? "Set Display Name" : authManager.localUsername)
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text(authManager.userProfile?.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(brandGoldLight)
                }
            }
            .padding(24)
            .background(Color.black.opacity(0.3))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(brandGold, lineWidth: 2)
            )
        }
    }
    
    private var statsSection: some View {
        VStack(spacing: 24) {
            sectionHeader("Statistics")
            
            VStack(spacing: 20) {
                // First Row
                HStack(spacing: 20) {
                    NavigationLink {
                        ProjectsListView()
                            .environmentObject(projectViewModel)
                    } label: {
                        StatCard(
                            title: "Projects",
                            value: "\(projectViewModel.projects.count)",
                            icon: "folder.fill",
                            accentColor: brandGold
                        )
                    }
                    .buttonStyle(.plain)
                    
                    if viewModel.isAdmin {
                        NavigationLink {
                            ClientListView()
                        } label: {
                            StatCard(
                                title: "Clients",
                                value: "\(viewModel.userCount)",
                                icon: "person.2",
                                accentColor: brandGold
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink {
                            SelectInvoiceView()
                        } label: {
                            StatCard(
                                title: "Invoices",
                                value: "\(viewModel.invoiceCount)",
                                icon: "doc.text.fill",
                                accentColor: brandGold
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Second Row
                HStack(spacing: 20) {
                    if viewModel.isAdmin {
                        NavigationLink {
                            SelectInvoiceView()
                        } label: {
                            StatCard(
                                title: "Invoices",
                                value: "\(viewModel.invoiceCount)",
                                icon: "doc.text.fill",
                                accentColor: brandGold
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    NavigationLink {
                        CompletedTasksView()
                            .environmentObject(projectViewModel)
                    } label: {
                        StatCard(
                            title: "Completed Tasks",
                            value: "\(projectViewModel.completedTasksCount)",
                            icon: "checkmark.circle.fill",
                            accentColor: brandGold
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(spacing: 24) {
            HStack {
                sectionHeader("Recent Activity")
                Spacer()
                if !activityManager.activities.isEmpty {
                    Button(action: {
                        showingClearConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(brandGold)
                            .font(.system(size: 20))
                    }
                }
            }
            
            if activityManager.activities.isEmpty {
                Text("No recent activity")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(activityManager.activities) { activity in
                            ActivityCard(
                                title: activity.title,
                                description: activity.description,
                                date: activity.formattedDate,
                                icon: activity.icon,
                                accentColor: brandGold
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .alert("Clear Activity History", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                withAnimation {
                    activityManager.clearActivities()
                }
            }
        } message: {
            Text("Are you sure you want to clear all activity history? This action cannot be undone.")
        }
    }
    
    private var accountSettingsSection: some View {
        VStack(spacing: 24) {
            sectionHeader("Account Settings")
            settingsButtons
        }
    }
    
    private var settingsButtons: some View {
        VStack(spacing: 16) {
            nameChangeSection
            passwordResetButton
            NavigationLink(destination: FAQView()) {
                SettingsButton(title: "FAQ", icon: "questionmark.circle")
            }
            privacyPolicyButton
            logoutButton
        }
    }
    
    private var nameChangeSection: some View {
        VStack(spacing: 8) {
            // Name Change Button
            if !isEditingUsername {
                SettingsButton(title: "Change Display Name", icon: "person.text.rectangle", action: {
                    tempUsername = authManager.localUsername
                    isEditingUsername = true
                })
            }
            
            // Name Change Field (when editing)
            if isEditingUsername {
                nameChangeEditor
            }
        }
    }
    
    private var nameChangeEditor: some View {
        VStack(spacing: 8) {
            TextField("Display Name", text: $tempUsername)
                .textFieldStyle(CustomTextFieldStyle())
                .padding(.horizontal)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.done)
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isEditingUsername = false
                        tempUsername = authManager.localUsername
                    }
                }
                .foregroundColor(.gray)
                
                Button("Save") {
                    if !tempUsername.isEmpty {
                        withAnimation(.easeOut(duration: 0.2)) {
                            authManager.localUsername = tempUsername
                            isEditingUsername = false
                        }
                    }
                }
                .foregroundColor(brandGold)
            }
        }
    }
    
    private var passwordResetButton: some View {
        SettingsButton(title: "Reset Password", icon: "lock.rotation", action: {
            showingPasswordReset = true
        })
    }
    
    private var privacyPolicyButton: some View {
        SettingsButton(title: "Privacy Policy", icon: "doc.text", action: {
            showingPrivacyPolicy = true
        })
    }
    
    private var logoutButton: some View {
        SettingsButton(title: "Sign Out", icon: "rectangle.portrait.and.arrow.right", action: {
            authManager.logout()
            dismiss()
        })
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(brandGold)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct StatisticsView: View {
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @EnvironmentObject var invoiceViewModel: InvoiceViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            // Projects Stat
            StatCard(
                title: "Projects",
                value: "\(projectViewModel.projects.count)",
                icon: "folder.fill"
            )
            
            // Invoices Stat
            StatCard(
                title: "Invoices",
                value: "\(invoiceViewModel.invoices.count)",
                icon: "doc.text.fill"
            )
            
            // Active Tasks Stat
            StatCard(
                title: "Active Tasks",
                value: "\(projectViewModel.activeTasksCount)",
                icon: "checklist"
            )
            
            // Completed Tasks Stat
            StatCard(
                title: "Completed Tasks",
                value: "\(projectViewModel.completedTasksCount)",
                icon: "checkmark.circle.fill"
            )
        }
        .padding(.horizontal)
    }
} 