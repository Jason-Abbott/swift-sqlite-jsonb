import Foundation

extension JSONBValue {
    /// - Parameter keyPath: Decoding key path used to describe errors
    func decode(for keyPath: CodingKeyPath) throws -> Bool {
        try assert(isOneOf: Self.boolean, decodingTo: Bool.self, at: keyPath)
        return type == .true
    }

    /// - Parameter keyPath: Decoding key path used to describe errors
    func decode(for keyPath: CodingKeyPath) throws -> UUID {
        let text = try assertText(decodingTo: UUID.self, at: keyPath)
        // if let value = Data(base64Encoded: text) { return value }

        throw DecodingError.typeMismatch(Data.self, DecodingError.Context(
            codingPath: keyPath.path,
            debugDescription: "Invalid UUID: \(text)"
        ))
    }

    /// - Parameter keyPath: Decoding key path used to describe errors
    func decode(for keyPath: CodingKeyPath) throws -> String {
        try assertText(at: keyPath)
    }

    /// - Parameter keyPath: Decoding key path used to describe errors
    func decode() throws -> String {
        if let text = String(bytes: payload, encoding: .utf8) { return text }
        throw JSONBError.invalidUTF8(payload)
    }

    /// - Parameter keyPath: Decoding key path used to describe errors
    func decode(for keyPath: CodingKeyPath) throws -> Double {
        let number: Float = try assertValue(isOneOf: Self.floats + Self.integers, at: keyPath)
        return Double(number)
    }

    /// - Parameter keyPath: Decoding key path used to describe errors
    func decode(for keyPath: CodingKeyPath) throws -> Float {
        try assertValue(isOneOf: Self.floats + Self.integers, at: keyPath)
    }

    /// - Parameter keyPath: Decoding key path used to describe errors
    func decode(for keyPath: CodingKeyPath) throws -> Date {
        let text = try assertText(decodingTo: Date.self, at: keyPath)
        let formatter = ISO8601DateFormatter()
        if let value = formatter.date(from: text) { return value }

        throw DecodingError.typeMismatch(Date.self, DecodingError.Context(
            codingPath: keyPath.path,
            debugDescription: "Invalid ISO 8601: \(text)"
        ))
    }

    /// - Parameter keyPath: Decoding key path used to describe errors
    func decode(for keyPath: CodingKeyPath) throws -> Data {
        let text = try assertText(decodingTo: Data.self, at: keyPath)
        if let value = Data(base64Encoded: text) { return value }

        throw DecodingError.typeMismatch(Data.self, DecodingError.Context(
            codingPath: keyPath.path,
            debugDescription: "Invalid Base64: \(text)"
        ))
    }

    /// - Parameter keyPath: Decoding key path used to describe errors
    func decode<T>(for keyPath: CodingKeyPath) throws -> T
        where T: BinaryInteger & Decodable & LosslessStringConvertible
    {
        try assertValue(isOneOf: Self.integers, at: keyPath)
    }

    /// - Parameter keyPath: Decoding key path used to describe errors
    func decode<T: RawRepresentable>(for keyPath: CodingKeyPath) throws -> T
        where T.RawValue == String
    {
        let text = try assertText(decodingTo: T.self, at: keyPath)
        if let value = T(rawValue: text) { return value }

        throw DecodingError.typeMismatch(T.self, DecodingError.Context(
            codingPath: keyPath.path,
            debugDescription: "Invalid rawValue: \(text)"
        ))
    }

    /// - Parameter keyPath: Decoding key path used to describe errors
    func decode<T: RawRepresentable>(for keyPath: CodingKeyPath) throws -> T
        where T.RawValue: BinaryInteger & LosslessStringConvertible
    {
        let number: T.RawValue = try assertValue(
            isOneOf: Self.integers,
            decodingTo: T.self,
            at: keyPath
        )
        if let value = T(rawValue: number) { return value }

        throw DecodingError.typeMismatch(T.self, DecodingError.Context(
            codingPath: keyPath.path,
            debugDescription: "Invalid rawValue: \(number)"
        ))
    }

    // MARK: assert

    /// Assert value is one of the given types and initialize as target type `T`, otherwise throw
    /// an error
    ///
    /// - Parameters:
    ///   - jsonTypes: `JSONBType`s that are valid for the current value
    ///   - targetType: Swift output type used to describe any errors. This may be the same as the
    ///     return type but can also differ if the return type here is the  *basis* for the final
    ///     target type. For example, `String` may be returned here in support of a `Date` or `Data`
    ///     target type.
    ///   - keyPath: Decoding key path used to describe any errors
    private func assertValue<T: LosslessStringConvertible>(
        isOneOf jsonTypes: [JSONBType],
        decodingTo targetType: Any.Type = T.self,
        at keyPath: CodingKeyPath
    ) throws -> T {
        let text = try assertText(asBasisFor: jsonTypes, decodingTo: targetType, at: keyPath)
        if let value = T(text) { return value }

        throw DecodingError.typeMismatch(T.self, DecodingError.Context(
            codingPath: keyPath.path,
            debugDescription: "Invalid string representation: \(text)"
        ))
    }

    /// Assert value is one of the given types and initialize as `String`, otherwise throw an
    /// error
    ///
    /// SQLite `TEXT` is the basis for several decoded Swift types
    ///
    /// - Parameters:
    ///   - jsonTypes: `JSONBType`s that are valid for the current value
    ///   - targetType: Swift output type used to describe any errors
    ///   - keyPath: Decoding key path used to describe any errors
    private func assertText(
        asBasisFor jsonTypes: [JSONBType] = Self.strings,
        decodingTo targetType: Any.Type = String.self,
        at keyPath: CodingKeyPath
    ) throws -> String {
        try assert(isOneOf: jsonTypes, decodingTo: targetType, at: keyPath)
        if payload.isEmpty { return "" }
        if let text = String(bytes: payload, encoding: .utf8) { return text }

        throw DecodingError.typeMismatch(String.self, DecodingError.Context(
            codingPath: keyPath.path,
            debugDescription: "Invalid UTF-8 bytes"
        ))
    }

    /// - Parameters:
    ///   - jsonTypes: `JSONBType`s that are valid for the current value
    ///   - targetType: Swift output type used to describe any errors
    ///   - keyPath: Decoding key path used to describe any errors
    private func assert(
        isOneOf jsonTypes: [JSONBType],
        decodingTo targetType: Any.Type,
        at keyPath: CodingKeyPath
    ) throws {
        guard jsonTypes.contains(type) else {
            throw DecodingError.typeMismatch(targetType, DecodingError.Context(
                codingPath: keyPath.path,
                debugDescription: "Invalid format: \(type)"
            ))
        }
        if payload.isEmpty, !Self.allowNoPayload.contains(type) {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: keyPath.path,
                debugDescription: "JSONB type missing payload: \(type)"
            ))
        }
    }
}

// MARK: - Support

extension JSONBValue {
    /// JSONB float types
    private static let floats: [JSONBType] = [.float, .float5]
    /// JSONB string types
    private static let strings: [JSONBType] = [.text, .textJ, .text5, .textRaw]
    /// JSONB boolean types
    private static let boolean: [JSONBType] = [.true, .false]
    /// JSONB integer types
    private static let integers: [JSONBType] = [.integer, .int5]
    /// JSONB types that should have no payload
    private static let neverHasPayload: [JSONBType] = [.null, .true, .false]
    /// JSONB types that may have no payload
    ///
    /// A string type without a payload is an empty string
    private static let allowNoPayload: [JSONBType] = strings + neverHasPayload
}
