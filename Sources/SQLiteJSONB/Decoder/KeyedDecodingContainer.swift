import Foundation

extension JSONBDecoder {
    /// ## Enumerations
    ///
    /// Cases within an enumeration are each processed as keyed containers by the synthesized
    /// Codable conformance (see reference). This can be unexpected when debugging and can be the
    /// cause of errors if an enumerations has custom encoding *or* custom decoding, but not both.
    ///
    /// For that matter, it is not obvious when a Codable implementation in a *protocol* that an
    /// enumeration conforms to may override the synthesized implementation within the
    /// enumeration itself (see ``StringDecodable`` discussion).
    ///
    /// ## References
    /// - Synthesized enumeration Codable [proposal][1]
    /// - Swift compiler [derived Codable conformance][2]
    /// - Swift compiler [derived CodingKeys][3]
    ///
    /// [1]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0295-codable-synthesis-for-enums-with-associated-values.md
    /// [2]: https://github.com/swiftlang/swift/blob/main/lib/Sema/DerivedConformanceCodable.cpp
    /// [3]: https://github.com/swiftlang/swift/blob/main/lib/Sema/DerivedConformanceCodingKey.cpp
    struct KeyedContainer<Key>: KeyedDecodingContainerProtocol where Key: CodingKey {
        private var decoder: JSONBDecoder

        var count: Int? { element.count }
        var allKeys: [Key] { element.keys.compactMap { Key(stringValue: $0) }}
        let element: JSONB.KeyedDecodeElement
        let keyPath: CodingKeyPath
        let userInfo: [CodingUserInfoKey: Any] = [:]
        var codingPath: [any CodingKey] { keyPath.path }

        init(
            for decoder: JSONBDecoder,
            at key: CodingKeyPath,
            with element: JSONB.KeyedDecodeElement
        ) throws {
            keyPath = key
            self.element = element
            self.decoder = decoder
        }

        public func contains(_ key: Key) -> Bool { element.contains(key) }

        public func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
            if let unkeyedElement = try element.unkeyed(key) {
                return UnkeyedContainer(
                    for: decoder,
                    at: keyPath.appending(key),
                    with: unkeyedElement
                )
            }
            throw notFound(key)
        }

        public func nestedContainer<NestedKey>(
            keyedBy _: NestedKey.Type,
            forKey key: Key
        ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
            if let keyedElement = try element.keyed(key) {
                return try KeyedDecodingContainer(KeyedContainer<NestedKey>(
                    for: decoder,
                    at: keyPath.appending(key),
                    with: keyedElement
                ))
            }
            throw notFound(key)
        }

        func superDecoder() throws -> any Decoder {
            try nestedDecoder(for: AnyContainerKey.super)
        }

        func superDecoder(forKey key: Key) throws -> any Decoder {
            try nestedDecoder(for: key)
        }

        private func nestedDecoder(for key: some CodingKey) throws -> any Decoder {
            let value = element[key] ?? .raw(JSONBValue.null)
            return JSONBDecoder(from: value, at: keyPath.appending(key))
        }
    }
}

// MARK: - Decode Overloads

extension JSONBDecoder.KeyedContainer {
    /// Decodes a `nil` value
    ///
    /// According to the Swift [JSONDecoder][1], the index only advances if the value is present
    ///
    /// [1]: https://github.com/swiftlang/swift-foundation/blob/a9dc42c58b6128ddb4f8867bf122372466841e58/Sources/FoundationEssentials/JSON/JSONDecoder.swift#L1547
    func decodeNil(forKey key: Key) throws -> Bool {
        if let value = element.decodeNil(key) { return value }
        return false
    }

    func decode(_: Bool.Type, forKey key: Key) throws -> Bool {
        if let value: Bool = try element.decode(key, for: keyPath) { return value }
        throw notFound(key)
    }

    func decode(_: Data.Type, forKey key: Key) throws -> Data {
        if let value: Data = try element.decode(key, for: keyPath) { return value }
        throw notFound(key)
    }

    func decode(_: Date.Type, forKey key: Key) throws -> Date {
        if let value: Date = try element.decode(key, for: keyPath) { return value }
        throw notFound(key)
    }

    func decode(_: Float.Type, forKey key: Key) throws -> Float {
        if let value: Float = try element.decode(key, for: keyPath) { return value }
        throw notFound(key)
    }

    func decode(_: Double.Type, forKey key: Key) throws -> Double {
        if let value: Double = try element.decode(key, for: keyPath) { return value }
        throw notFound(key)
    }

    func decode(_: String.Type, forKey key: Key) throws -> String {
        if let value: String = try element.decode(key, for: keyPath) { return value }
        throw notFound(key)
    }

    func decode<T>(_: T.Type, forKey key: Key) throws -> T
        where T: BinaryInteger & Decodable & LosslessStringConvertible
    {
        if let value: T = try element.decode(key, for: keyPath) { return value }
        throw notFound(key)
    }

    /// Decode a complex type
    ///
    /// > Developer Note: This does not correctly handle *nested* `DecodableWithConfiguration`
    ///   types. In my (@jason-abbott) personal implementation of this method, I have conditions
    ///   like `T.self == AttributedString.self` in which I assign the configuration required in
    ///   my usage.
    ///
    /// ## References
    /// - Swift Foundation [JSONDecoder.unwrap()][1]
    ///
    /// [1]: https://github.com/swiftlang/swift-foundation/blob/c64dcd8347554db347492e0643d1e5fbc4ccfd2b/Sources/FoundationEssentials/JSON/JSONDecoder.swift#L600
    func decode<T>(_: T.Type, forKey key: Key) throws -> T where T: Decodable {
        if let value = element[key] {
             try T(from: JSONBDecoder(from: value, at: keyPath.appending(key)))
        } else {
            throw notFound(key)
        }
    }

    private func notFound(_ key: some CodingKey) -> DecodingError {
        DecodingError.keyNotFound(key, DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "Missing expected value at key: \(key.stringValue)"
        ))
    }
}
