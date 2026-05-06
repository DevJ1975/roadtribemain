//
//  RidesHubView.swift
//  Road Tribe
//

import SwiftUI
import SwiftData

/// Root view for the Rides tab — combines Trips and Journal with a segmented picker.
struct RidesHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationService.self) private var locationService
    @Environment(RideTrackingService.self) private var rideTracking
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]
    @Query(sort: \JournalEntry.timestamp, order: .reverse) private var allEntries: [JournalEntry]
    @Query(sort: \Motorcycle.createdAt) private var motorcycles: [Motorcycle]
    @State private var selectedSegment: RidesSegment = .trips
    @State private var showingCreateTrip = false
    @State private var showingCreateEntry = false
    @State private var showingQuickCapture = false
    @State private var weatherService = RoadWeatherService()
    @State private var showRideWeather = false

    enum RidesSegment: String, CaseIterable {
        case trips = "Trips"
        case journal = "Journal"
        case history = "History"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Group {
                    if let condition = weatherService.currentCondition {
                        RideabilityCard(score: RideabilityScore.compute(from: condition))
                    } else {
                        preRideWeatherCard
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.top, Spacing.xs)
                .onTapGesture { showRideWeather = true }

                Picker("Section", selection: $selectedSegment) {
                    ForEach(RidesSegment.allCases, id: \.self) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)

                switch selectedSegment {
                case .trips:
                    tripsContent
                case .journal:
                    journalContent
                case .history:
                    routeHistoryContent
                }
            }
            .task {
                await weatherService.fetchWeather(
                    at: locationService.currentLocation ?? .sanFrancisco
                )
            }
            .navigationTitle("Rides")
            .toolbar {
                // Quick-capture journal entry — only visible while riding,
                // pre-fills trip/location/weather context.
                if rideTracking.isRiding {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showingQuickCapture = true
                        } label: {
                            Label("Quick Note", systemImage: "square.and.pencil")
                        }
                    }
                }

                // Maintenance dashboard — only when the rider has a bike on file.
                if let primaryBike = motorcycles.first {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(value: MaintenanceDestination.due(primaryBike)) {
                            Image(systemName: "wrench.and.screwdriver")
                        }
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if selectedSegment == .trips {
                            showingCreateTrip = true
                        } else {
                            showingCreateEntry = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateTrip) {
                CreateTripView()
            }
            .sheet(isPresented: $showingCreateEntry) {
                CreateJournalEntryView()
            }
            .sheet(isPresented: $showingQuickCapture) {
                QuickJournalCaptureView(weatherService: weatherService)
            }
            .fullScreenCover(isPresented: $showRideWeather) {
                RideWeatherView()
            }
            .navigationDestination(for: Trip.self) { trip in
                TripDetailView(trip: trip)
            }
            .navigationDestination(for: JournalEntry.self) { entry in
                JournalEntryDetailView(entry: entry)
            }
            .navigationDestination(for: MaintenanceDestination.self) { dest in
                switch dest {
                case .due(let bike):
                    MaintenanceDueView(motorcycle: bike)
                }
            }
        }
    }

    // MARK: - Pre-Ride Weather Card

    private var preRideWeatherCard: some View {
        VStack(spacing: Spacing.xs) {
            if weatherService.isLoading {
                HStack(spacing: Spacing.xs) {
                    ProgressView()
                    Text("Checking weather...")
                        .font(.rtCaption)
                        .foregroundStyle(.secondary)
                }
            } else if let condition = weatherService.currentCondition {
                HStack {
                    // Left: temp + feels like
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: condition.symbolName)
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(condition.temperatureFormatted)
                                .font(.rtHeadline)
                            Text("Feels like \(condition.feelsLikeFormatted)")
                                .font(.rtCaption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Right: wind + humidity
                    VStack(alignment: .trailing, spacing: 2) {
                        Label("\(Int(condition.windSpeedMPH)) mph", systemImage: "wind")
                            .font(.rtCaption)
                        Label(condition.humidityFormatted, systemImage: "humidity.fill")
                            .font(.rtCaption)
                    }
                    .foregroundStyle(.secondary)
                }

                HStack {
                    if weatherService.weatherAlerts.isEmpty {
                        Label("Good riding weather", systemImage: "checkmark.seal.fill")
                            .font(.rtCaptionBold)
                            .foregroundStyle(.green)
                    } else {
                        Label("Check alerts", systemImage: "exclamationmark.triangle.fill")
                            .font(.rtCaptionBold)
                            .foregroundStyle(.orange)
                    }

                    Spacer()

                    Button {
                        showRideWeather = true
                    } label: {
                        Text("Ride Weather")
                            .font(.rtCaptionBold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(Color.rtDiscoverColor, in: Capsule())
                    }
                }
            } else {
                // Weather unavailable or not yet loaded
                HStack {
                    Image(systemName: "cloud.sun.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pre-Ride Weather")
                            .font(.rtHeadline)
                        if let error = weatherService.lastError {
                            Text(error)
                                .font(.rtCaption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        } else {
                            Text("Check conditions before you ride")
                                .font(.rtCaption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        showRideWeather = true
                    } label: {
                        Text("Ride Weather")
                            .font(.rtCaptionBold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(Color.rtDiscoverColor, in: Capsule())
                    }
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color.rtSurfaceFallback, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
    }

    // MARK: - Trips Content

    private var tripsContent: some View {
        Group {
            if trips.isEmpty {
                Spacer()
                VStack(spacing: Spacing.xs) {
                    Image(systemName: "motorcycle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("No Trips Yet")
                        .font(.rtTitle)
                        .foregroundStyle(.secondary)
                    Text("Plan your first ride adventure!")
                        .font(.rtCaption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(trips) { trip in
                            NavigationLink(value: trip) {
                                TripCardView(trip: trip)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.bottom, Spacing.xl)
                }
                .refreshable {
                    try? await Task.sleep(for: .seconds(0.5))
                }
            }
        }
    }

    // MARK: - Route History Content

    @ViewBuilder
    private var routeHistoryContent: some View {
        RecordedRouteListView()
    }

    // MARK: - Journal Content

    private var journalContent: some View {
        Group {
            if allEntries.isEmpty {
                Spacer()
                VStack(spacing: Spacing.xs) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("No Journal Entries")
                        .font(.rtTitle)
                        .foregroundStyle(.secondary)
                    Text("Capture moments from your trips.")
                        .font(.rtCaption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                List {
                    ForEach(allEntries) { entry in
                        NavigationLink(value: entry) {
                            journalRow(entry)
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    try? await Task.sleep(for: .seconds(0.5))
                }
            }
        }
    }

    private func journalRow(_ entry: JournalEntry) -> some View {
        HStack(spacing: Spacing.xs) {
            if let photoData = entry.photoDataItems.first, let uiImage = ImageCache.shared.image(from: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
            } else {
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .fill(Color.rtSurfaceFallback)
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "book.fill")
                            .foregroundStyle(.tertiary)
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.rtTitle)
                    .lineLimit(1)
                Text(entry.content)
                    .font(.rtCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(Formatters.mediumDate.string(from: entry.timestamp))
                    .font(.rtCaption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
