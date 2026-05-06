//
//  GPXShareLink.swift
//  Road Tribe
//
//  Wraps SwiftUI's ShareLink with GPXExporter so any view can offer a
//  one-tap "Share GPX" action for a Trip.
//

import SwiftUI
import UniformTypeIdentifiers

/// Transferable wrapper so `ShareLink` can produce a GPX file from a Trip
/// without leaking a temp file URL onto the call site.
struct ExportedGPX: Transferable {
    let url: URL
    let filename: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .xml) { exported in
            SentTransferredFile(exported.url)
        }
        .suggestedFileName { $0.filename }
    }
}

/// One-tap GPX share button for a Trip. Uses `GPXExporter.exportToFile`,
/// which writes to the temporary directory; the system share sheet copies
/// the bytes out so it's safe to leave the temp file behind.
struct GPXShareLink<Label: View>: View {
    let trip: Trip
    @ViewBuilder var label: () -> Label

    @State private var exported: ExportedGPX?
    @State private var lastError: String?
    @State private var showError = false

    var body: some View {
        Group {
            if let exported {
                ShareLink(item: exported, preview: SharePreview(exported.filename))
            } else {
                Button {
                    prepare()
                } label: {
                    label()
                }
            }
        }
        .alert("Couldn't export GPX", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(lastError ?? "Unknown error")
        }
    }

    private func prepare() {
        do {
            let url = try GPXExporter.exportToFile(trip: trip)
            exported = ExportedGPX(url: url, filename: url.lastPathComponent)
        } catch {
            lastError = error.localizedDescription
            showError = true
        }
    }
}

extension GPXShareLink where Label == SwiftUI.Label<Text, Image> {
    /// Convenience initialiser using the standard "Share GPX" label.
    init(trip: Trip) {
        self.trip = trip
        self.label = { Label("Share GPX", systemImage: "square.and.arrow.up") }
    }
}
