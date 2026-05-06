//
//  AddMemorialView.swift
//  Road Tribe
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddMemorialView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let coordinate: CLLocationCoordinate2D
    let authorID: UUID

    @State private var riderName = ""
    @State private var dateOfPassing = Date()
    @State private var tribute = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var isSaving = false

    private var canPlace: Bool {
        !riderName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Header
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: Spacing.xs) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.85, blue: 0.3),
                                            Color(red: 1.0, green: 0.5, blue: 0.05)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            Text("Place a Memorial")
                                .font(.rtHeadline)
                            Text("Honor a fallen rider at this location")
                                .font(.rtCaption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, Spacing.xs)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)

                // Rider Details
                Section("Rider") {
                    TextField("Rider's Name", text: $riderName)

                    DatePicker(
                        "Date of Passing",
                        selection: $dateOfPassing,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                }

                // Tribute
                Section("Tribute") {
                    TextField(
                        "Share a memory or words of remembrance…",
                        text: $tribute,
                        axis: .vertical
                    )
                    .lineLimit(4...8)
                }

                // Photo
                Section("Photo (Optional)") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        HStack {
                            if let photoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                                Text("Change Photo")
                                    .font(.rtBody)
                            } else {
                                Label("Add Photo", systemImage: "photo.badge.plus")
                                    .font(.rtBody)
                                    .foregroundStyle(DesignSystem.Colors.brand)
                            }
                        }
                    }
                }

                // Location note
                Section {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(Color.purple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Memorial Location")
                                .font(.rtCaptionBold)
                            Text(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))
                                .font(.rtCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Memorial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Place") {
                        Task { await placeMemorial() }
                    }
                    .disabled(!canPlace || isSaving)
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: photoItem) {
                Task {
                    photoData = try? await photoItem?.loadTransferable(type: Data.self)
                }
            }
        }
    }

    private func placeMemorial() async {
        isSaving = true
        let name = riderName.trimmingCharacters(in: .whitespaces)
        let memorial = FallenRiderMemorial(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            riderName: name,
            dateOfPassing: dateOfPassing,
            tribute: tribute.trimmingCharacters(in: .whitespaces),
            authorID: authorID,
            photoData: photoData
        )
        modelContext.insert(memorial)
        try? modelContext.save()
        DesignSystem.Haptics.success()
        dismiss()
    }
}
