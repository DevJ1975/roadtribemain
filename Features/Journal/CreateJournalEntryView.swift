//
//  CreateJournalEntryView.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import SwiftUI
import SwiftData
import PhotosUI

/// A form to create a new journal entry.
struct CreateJournalEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]

    @State private var title = ""
    @State private var content = ""
    @State private var selectedMood: JournalMood?
    @State private var selectedTrip: Trip?

    // Photo state
    @State private var photosPickerItems: [PhotosPickerItem] = []
    @State private var capturedPhotos: [Data] = []
    @State private var showingCamera = false

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What's on your mind?") {
                    TextField("Title", text: $title)
                    TextField("Write your thoughts...", text: $content, axis: .vertical)
                        .lineLimit(5...12)
                }

                // Photos section
                Section("Photos") {
                    if !capturedPhotos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.xs) {
                                ForEach(capturedPhotos.indices, id: \.self) { index in
                                    if let uiImage = UIImage(data: capturedPhotos[index]) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))

                                            Button {
                                                capturedPhotos.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.white, .black.opacity(0.6))
                                                    .font(.title3)
                                            }
                                            .offset(x: 4, y: -4)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, Spacing.xxxs)
                        }
                    }

                    HStack(spacing: Spacing.sm) {
                        PhotosPicker(
                            selection: $photosPickerItems,
                            maxSelectionCount: 10,
                            matching: .images
                        ) {
                            Label("Library", systemImage: "photo.on.rectangle")
                                .font(.rtCallout)
                        }

                        Button {
                            showingCamera = true
                        } label: {
                            Label("Camera", systemImage: "camera")
                                .font(.rtCallout)
                        }
                    }
                }

                Section("Mood") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(JournalMood.allCases, id: \.self) { mood in
                                Button {
                                    selectedMood = selectedMood == mood ? nil : mood
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(mood.emoji)
                                            .font(.title)
                                        Text(mood.displayName)
                                            .font(.rtCaption)
                                    }
                                    .padding(Spacing.xxs)
                                    .background(
                                        selectedMood == mood
                                            ? Color.rtPrimaryFallback.opacity(0.2)
                                            : Color.clear,
                                        in: RoundedRectangle(cornerRadius: CornerRadius.small)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if !trips.isEmpty {
                    Section("Link to Trip") {
                        Picker("Trip", selection: $selectedTrip) {
                            Text("None").tag(nil as Trip?)
                            ForEach(trips) { trip in
                                Text(trip.title).tag(trip as Trip?)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onChange(of: photosPickerItems) { _, newItems in
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            // Compress to JPEG to save space
                            if let uiImage = UIImage(data: data),
                               let jpeg = uiImage.jpegData(compressionQuality: 0.7) {
                                capturedPhotos.append(jpeg)
                            }
                        }
                    }
                    photosPickerItems.removeAll()
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { imageData in
                    capturedPhotos.append(imageData)
                }
            }
        }
    }

    private func saveEntry() {
        let entry = JournalEntry(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            photoDataItems: capturedPhotos,
            mood: selectedMood
        )
        if let selectedTrip {
            entry.trip = selectedTrip
        }
        modelContext.insert(entry)
    }
}

// MARK: - Camera View (UIImagePickerController wrapper)

struct CameraView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onCapture: (Data) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss, onCapture: onCapture)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let dismiss: DismissAction
        let onCapture: (Data) -> Void

        init(dismiss: DismissAction, onCapture: @escaping (Data) -> Void) {
            self.dismiss = dismiss
            self.onCapture = onCapture
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.7) {
                onCapture(data)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

#Preview {
    CreateJournalEntryView()
        .modelContainer(try! PersistenceService.previewContainer())
}
