import Security

enum KeychainHelper {
    private static let service = "com.aivisionassistant.apikey"

    static func save(_ value: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query = NSMutableDictionary()
        query[kSecClass] = kSecClassGenericPassword
        query[kSecAttrService] = service
        query[kSecAttrAccount] = account
        SecItemDelete(query)
        query[kSecValueData] = data
        SecItemAdd(query, nil)
    }

    static func load(account: String) -> String? {
        let query = NSMutableDictionary()
        query[kSecClass] = kSecClassGenericPassword
        query[kSecAttrService] = service
        query[kSecAttrAccount] = account
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(account: String) {
        let query = NSMutableDictionary()
        query[kSecClass] = kSecClassGenericPassword
        query[kSecAttrService] = service
        query[kSecAttrAccount] = account
        SecItemDelete(query)
    }
}
