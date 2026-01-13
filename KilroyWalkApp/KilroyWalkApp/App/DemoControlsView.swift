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

            Section("Frontier Zone") {
                Picker("Location Mode", selection: $viewModel.locationMode) {
                    ForEach(AppViewModel.DemoLocationMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)

                LabeledContent("Summary", value: viewModel.locationSummary)
                if let poi = viewModel.currentPOILabel {
                    LabeledContent("POI", value: poi)
                }

                if let moment = viewModel.activeMoment {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active Moment")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(moment.title)
                            .font(.headline)
                        if let subtitle = moment.subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    LabeledContent("Active Moment", value: "None")
                }

                Text(viewModel.momentDiagnostics)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                ForEach(AppViewModel.ManualMoment.allCases) { manual in
                    Button(manual.buttonLabel) {
                        viewModel.triggerManualMoment(manual)
                    }
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

            Section("Audio") {
                Button("Test Whisper") {
                    viewModel.testWhisper()
                }
            }
        }
        .navigationTitle("Demo Controls")
    }
}
