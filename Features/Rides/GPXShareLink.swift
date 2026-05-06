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

/// What kind of object we're exporting. Resolved at tap time so the file
/// isn't generated until the user actually wants to share.
private enum GPXSource {
    case trip(Trip)
    case route(RecordedRoute)

    func write() throws -> URL {
        switch self {
        case .trip(let trip):   return try GPXExporter.exportToFile(trip: trip)
        case .route(let route): return try GPXExporter.exportToFile(route: route)
        }
    }
}

/// One-tap GPX share button. Works for either a planned `Trip` (waypoints)
/// or a recorded `RecordedRoute` (GPS track). Uses `GPXExporter.exportToFile`,
/// which writes to the temporary directory; the system share sheet copies
/// the bytes out so it's safe to leave the temp file behind.
struct GPXShareLink<Label: View>: View {
    private let source: GPXSource
    @ViewBuilder private var label: () -> Label

    @State private var exported: ExportedGPX?
    @State private var lastError: String?
    @State private var showError = false

    init(trip: Trip, @ViewBuilder label: @escaping () -> Label) {
        self.source = .trip(trip)
        self.label = label
    }

    init(route: RecordedRoute, @ViewBuilder label: @escaping () -> Label) {
        self.source = .route(route)
        self.label = label
    }

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
            let url = try source.write()
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
        self.init(trip: trip) {
            SwiftUI.Label("Share GPX", systemImage: "square.and.arrow.up")
        }
    }

    init(route: RecordedRoute) {
        self.init(route: route) {
            SwiftUI.Label("Share GPX", systemImage: "square.and.arrow.up")
        }
    }
}
