//
//  GPXExporter.swift
//  Road Tribe
//

import Foundation

/// Generates GPX 1.1 XML files from trip waypoints.
struct GPXExporter {

    /// Generate a GPX XML string from a trip's waypoints.
    static func generateGPX(for trip: Trip) -> String {
        let iso = ISO8601DateFormatter()
        let sorted = trip.waypoints.sorted { $0.sortOrder < $1.sortOrder }

        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Road Tribe"
             xmlns="http://www.topografix.com/GPX/1/1">
          <metadata>
            <name>\(escapeXML(trip.title))</name>
            <desc>\(escapeXML(trip.tripDescription))</desc>
            <time>\(iso.string(from: trip.startDate))</time>
          </metadata>
          <trk>
            <name>\(escapeXML(trip.title))</name>
            <trkseg>
        """

        for waypoint in sorted {
            xml += "\n      <trkpt lat=\"\(waypoint.latitude)\" lon=\"\(waypoint.longitude)\">"
            xml += "\n        <name>\(escapeXML(waypoint.name))</name>"
            if let arrival = waypoint.arrivalDate {
                xml += "\n        <time>\(iso.string(from: arrival))</time>"
            }
            xml += "\n      </trkpt>"
        }

        xml += """

            </trkseg>
          </trk>
        </gpx>
        """
        return xml
    }

    /// Write GPX to a temporary file and return the URL for sharing.
    static func exportToFile(trip: Trip) throws -> URL {
        let gpxString = generateGPX(for: trip)
        let sanitizedName = sanitizedFileName(from: trip.title)
        let fileName = "\(sanitizedName).gpx"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try gpxString.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// Produces a non-empty, filesystem-safe stem for the GPX file name.
    static func sanitizedFileName(from title: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:*?\"<>|")
            .union(.controlCharacters)
        let sanitized = title
            .components(separatedBy: invalid)
            .joined(separator: "-")
            .replacingOccurrences(of: " ", with: "_")
            .trimmingCharacters(in: .init(charactersIn: "._-"))
        return sanitized.isEmpty ? "trip" : sanitized
    }

    private static func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
