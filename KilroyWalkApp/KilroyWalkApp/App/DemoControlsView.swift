import SwiftUI

struct DemoControlsView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        Form {
            Section("Context") {
                LabeledContent("Place", value: viewModel.context.placeId ?? "Unknown")
                TextField("Floor band (e.g. SKY-LOBBY)", text: $viewModel.floorBandInput)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                Button("Set FloorBand") {
                    viewModel.setFloorBand()
                }
            }

            Section("Manual Triggers") {
                Button("Trigger Arrival Whisper") {
                    viewModel.triggerArrival()
                }
                Button("Trigger Floor Event") {
                    Task {
                        await viewModel.triggerFloorEvent()
                    }
                }
            }

            Section("Permissions") {
                TextField("Permission token", text: $viewModel.permissionTokenInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Store Permission Token") {
                    viewModel.storePermissionToken()
                }
            }
        }
        .navigationTitle("Demo Controls")
    }
}
