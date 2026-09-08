//
//  ProductService.swift
//  Trace
//
//  Open Food Facts lookups. Knows nothing about the scanner.
//

import Foundation

enum ProductResult {
    case found(Product)
    case notFound
    case failed(Error)
}

enum ProductServiceError: Error {
    /// The barcode could not form a request path.
    case invalidBarcode(String)
}

struct ProductService {

    private static let host = "https://world.openfoodfacts.org/api/v2/product/"
    private static let userAgent = "Trace/1.0 (iOS; student project)"

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Looks up a barcode, retrying once without a leading zero on a miss.
    ///
    /// Throws only for a barcode that cannot be requested at all. Transport
    /// and decoding failures come back as `.failed`.
    func fetchProduct(barcode: String) async throws -> ProductResult {
        let result = try await lookup(barcode)

        guard case .notFound = result,
              let stripped = Self.strippingLeadingZero(from: barcode) else {
            return result
        }

        // iOS reports UPC-A as 13 digits with a leading zero, so the miss may
        // just be the wrong form of the same code. One retry, no more.
        return try await lookup(stripped)
    }

    private func lookup(_ barcode: String) async throws -> ProductResult {
        guard Self.isRequestable(barcode),
              let url = URL(string: Self.host + barcode + ".json") else {
            throw ProductServiceError.invalidBarcode(barcode)
        }

        var request = URLRequest(url: url)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

        do {
            // The HTTP status is deliberately ignored: a missing product is a
            // 200 carrying "status": 0.
            let (data, _) = try await session.data(for: request)
            let response = try JSONDecoder().decode(ProductResponse.self, from: data)

            guard response.status == 1, let product = response.product else {
                return .notFound
            }
            return .found(product)
        } catch {
            return .failed(error)
        }
    }

    private static func isRequestable(_ barcode: String) -> Bool {
        !barcode.isEmpty && barcode.allSatisfy(\.isNumber)
    }

    private static func strippingLeadingZero(from barcode: String) -> String? {
        guard barcode.count > 1, barcode.hasPrefix("0") else { return nil }
        return String(barcode.dropFirst())
    }
}
