import SwiftUI

struct DebugLogView: View {
    let debugLog: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(debugLog)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#dca54e"))
                }
            }
        }
    }
} 