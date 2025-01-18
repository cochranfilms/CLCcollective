import SwiftUI
import Foundation

class PackagesViewModel: ObservableObject {
    @Published var selectedPackages: Set<Package> = []
    @Published var showingAuthAlert = false
    @Published var showingContactForm = false
    @Published var isAppearing = false
    
    var totalAmount: Double {
        Double(selectedPackages.reduce(0) { $0 + $1.price })
    }
    
    func togglePackage(_ package: Package) {
        if selectedPackages.contains(package) {
            selectedPackages.remove(package)
        } else {
            selectedPackages.insert(package)
        }
    }
    
    func clearSelections() {
        selectedPackages.removeAll()
    }
} 