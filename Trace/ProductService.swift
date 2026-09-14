// open food facts lookups, knows nothing about the scanner

import Foundation

enum ProductResult {
    case found(Product)
    case notFound
    case failed(Error)
}

enum ProductServiceError: Error {
    // the barcode could not form a request path
    case invalidBarcode(String)
}

struct ProductService {

    private static let host = "https://world.openfoodfacts.org/api/v2/product/"
    private static let userAgent = "Trace/1.0 (iOS; student project)"

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // looks up a barcode, throws only when it cannot be requested at all
    func fetchProduct(barcode: String) async throws -> ProductResult {
        let result = try await lookup(barcode)

        guard case .notFound = result,
              let stripped = Self.strippingLeadingZero(from: barcode) else {
            return result
        }

        // ios reports upc-a with a leading zero, so retry once without it
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
            // http status ignored, a missing product is a 200 with "status": 0
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
