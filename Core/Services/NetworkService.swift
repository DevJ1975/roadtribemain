//
//  NetworkService.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation

/// A lightweight async/await networking layer built on URLSession.
actor NetworkService {

    static let shared = NetworkService()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session

        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - GET

    func get<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request = applyHeaders(to: request)

        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - POST

    func post<Body: Encodable, Response: Decodable>(
        _ body: Body,
        to url: URL,
        expecting type: Response.Type
    ) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(body)
        request = applyHeaders(to: request)

        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return try decoder.decode(Response.self, from: data)
    }

    // MARK: - PUT

    func put<Body: Encodable>(
        _ body: Body,
        to url: URL
    ) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try encoder.encode(body)
        request = applyHeaders(to: request)

        let (_, response) = try await session.data(for: request)
        try validate(response: response)
    }

    // MARK: - DELETE

    func delete(url: URL) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request = applyHeaders(to: request)

        let (_, response) = try await session.data(for: request)
        try validate(response: response)
    }

    // MARK: - Helpers

    private func applyHeaders(to request: URLRequest) -> URLRequest {
        var request = request
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // TODO: Add auth token header when AuthService is connected
        return request
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - Errors

enum NetworkError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .httpError(let statusCode):
            return "Request failed with status code \(statusCode)."
        case .decodingFailed:
            return "Unable to process the server response."
        }
    }
}
