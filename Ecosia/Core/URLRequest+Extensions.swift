import Foundation

extension URLRequest {

    public mutating func withAuthParameters(environment: Environment = Environment.current) -> URLRequest {
        if let auth = environment.auth {
            setValue(auth.id, forHTTPHeaderField: CloudflareKeyProvider.clientId)
            setValue(auth.secret, forHTTPHeaderField: CloudflareKeyProvider.clientSecret)
        }
        return self
	}

    /// This function provides an additional HTTP request header when loading SERP through native UI (i.e. submitting a search)
    /// to help SERP decide which market to serve.
    public mutating func addLanguageRegionHeader() {
        setValue(Locale.current.identifierWithDashedLanguageAndRegion, forHTTPHeaderField: "x-ecosia-app-language-region")
    }
}
