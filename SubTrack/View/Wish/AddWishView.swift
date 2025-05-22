import SwiftUI

struct AddWishView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings
    @ObservedObject var viewModel: WishViewModel
    
    @State private var title: String = ""
    @State private var description: String = ""
    
    var body: some View {
        Form {
            Section {
                TextField("Title", text: $viewModel.newTitle)
            } header: {
                Text("Title")
            }
            
            Section {
                TextEditor(text: $viewModel.newContent)
                    .frame(minHeight: 100)
            } header: {
                Text("Description")
            } footer: {
                Text("Any wishes that needs Internet connections will be considered carefully due to the budget constraints of the project.")
            }
        }
        .navigationTitle("Submit a Wish")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Submit") {
                    viewModel.submitWish()
                    dismiss()
                }
                .disabled(viewModel.newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            viewModel.setDeviceId(appSettings.deviceID)
        }
    }
}
