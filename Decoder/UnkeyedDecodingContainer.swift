import Foundation

extension JSONBDecoder {
    /// Container for decoding unkeyed (array) values
    ///
    /// This container keeps track of the current index so the caller can simply request the next
    /// value. Importantly, the index should be incremented only if the value is of the expected
    /// type. Otherwise an error is thrown.
    ///
    /// This behavior is expected, for example, by `AttributedString` which encodes attributes
    /// alongside text in an every-other array if there are ten or fewer sets of attributes,
    /// otherwise it encodes them to a lookup table referenced by an index stored alongside the
    /// text (see [source code][1]).
    ///
    /// ```swift
    /// if self._guts.runs.count <= 10 { ... }
    /// ```
    /// Thus, when decoding, the `AttributedString` tests whether the next unkeyed item is an
    /// integer, referring to the attribute lookup table, or a keyed container of attributes
    /// themselves (see [source code][2]).
    ///
    /// ```swift
    /// if let tableIndex = try? runsContainer.decode(Int.self) { ... }
    /// ```
    ///
    /// [1]: https://github.com/swiftlang/swift-foundation/blob/e43505ce4a97177c40d0b8e5c1751e4cc4142b0c/Sources/FoundationEssentials/AttributedString/AttributedStringCodable.swift#L181
    /// [2]: https://github.com/swiftlang/swift-foundation/blob/e43505ce4a97177c40d0b8e5c1751e4cc4142b0c/Sources/FoundationEssentials/AttributedString/AttributedStringCodable.swift#L265
    struct UnkeyedContainer: UnkeyedDecodingContainer {
        private var decoder: JSONBDecoder

        let count: Int?
        let element: JSONB.UnkeyedDecodeElement
        let keyPath: CodingKeyPath
        var isAtEnd: Bool { currentIndex >= (count ?? 0) }
        let userInfo: [CodingUserInfoKey: Any] = [:]
        var currentIndex: Int = 0
        var currentIndexKey: AnyContainerKey { .init(index: currentIndex) } // needed?

        public var codingPath: [any CodingKey] { keyPath.path }

        init(
            for decoder: JSONBDecoder,
            at keyPath: CodingKeyPath,
            with element: JSONB.UnkeyedDecodeElement
        ) {
            self.decoder = decoder
            self.element = element
            self.keyPath = keyPath
            count = element.count
        }

        mutating func nestedUnkeyedContainer() throws -> any UnkeyedDecodingContainer {
            guard let unkeyedElement = try element.unkeyed(at: currentIndex) else {
                throw notFound(JSONB.UnkeyedDecodeElement.self)
            }
            currentIndex += 1
            return UnkeyedContainer(
                for: decoder,
                at: keyPath.appending(index: currentIndex),
                with: unkeyedElement
            )
        }

        mutating func nestedContainer<NestedKey>(
            keyedBy _: NestedKey.Type
        ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
            guard let keyedElement = try element.keyed(at: currentIndex) else {
                throw notFound(JSONB.KeyedDecodeElement.self)
            }
            currentIndex += 1
            return try KeyedDecodingContainer(KeyedContainer(
                for: decoder,
                at: keyPath.appending(index: currentIndex),
                with: keyedElement
            ))
        }

        /// Encodes a nested container and returns an `Encoder` instance for encoding
        /// `super` into that container.
        ///
        /// - returns: A new encoder to pass to `super.encode(to:)`.
        mutating func superDecoder() throws(DecodingError) -> any Decoder {
            guard let value = element[safe: currentIndex] else {
                throw notFound(JSONBDecoder.self)
            }
            currentIndex += 1
            return JSONBDecoder(from: value, at: keyPath.appending(index: currentIndex))
        }
    }
}

// MARK: - Decode Overloads

extension JSONBDecoder.UnkeyedContainer {
    /// Decodes a `nil` value
    ///
    /// According to the Swift [JSONDecoder][1], the index only advances if the value is present
    /// even though no error is thrown
    ///
    /// [1]: https://github.com/swiftlang/swift-foundation/blob/a9dc42c58b6128ddb4f8867bf122372466841e58/Sources/FoundationEssentials/JSON/JSONDecoder.swift#L1547
    mutating func decodeNil() throws -> Bool {
        if let value = element.decodeNil(at: currentIndex) {
            currentIndex += 1
            return value
        }
        return false
    }

    mutating func decode(_ type: Bool.Type) throws -> Bool {
        if let value: Bool = try element.decode(at: currentIndex, for: keyPath) {
            currentIndex += 1
            return value
        }
        throw notFound(type)
    }

    mutating func decode(_ type: Data.Type) throws -> Data {
        if let value: Data = try element.decode(at: currentIndex, for: keyPath) {
            currentIndex += 1
            return value
        }
        throw notFound(type)
    }

    mutating func decode(_ type: Date.Type) throws -> Date {
        if let value: Date = try element.decode(at: currentIndex, for: keyPath) {
            currentIndex += 1
            return value
        }
        throw notFound(type)
    }

    mutating func decode(_ type: Float.Type) throws -> Float {
        if let value: Float = try element.decode(at: currentIndex, for: keyPath) {
            currentIndex += 1
            return value
        }
        throw notFound(type)
    }

    mutating func decode(_ type: Double.Type) throws -> Double {
        if let value: Double = try element.decode(at: currentIndex, for: keyPath) {
            currentIndex += 1
            return value
        }
        throw notFound(type)
    }

    mutating func decode(_ type: String.Type) throws -> String {
        if let value: String = try element.decode(at: currentIndex, for: keyPath) {
            currentIndex += 1
            return value
        }
        throw notFound(type)
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        guard let value = element[safe: currentIndex] else { throw notFound(type) }
        let result = try T(from: JSONBDecoder(from: value, at: keyPath.appending(currentIndexKey)))
        currentIndex += 1
        return result
    }

    private func notFound<T>(_: T.Type) -> DecodingError {
        DecodingError.valueNotFound(
            T.self,
            DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Missing expected value at index \(currentIndex)"
            )
        )
    }
}
