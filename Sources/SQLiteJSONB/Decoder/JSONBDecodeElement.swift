import Foundation

extension JSONB {
    /// Source bytes sliced (`ArraySlice`) into keyed and unkeyed caches
    enum DecodeElement {
        /// An unparsed JSONB value
        ///
        /// It may be a single value, appropriate for `SingleValueDecodingContainer`, or an
        /// (unkeyed) array or (keyed) object
        case raw(JSONBValue)
        /// `KeyedDecodingContainer` cache
        case keyed(KeyedDecodeElement)
        /// `UnkeyedDecodingContainer` cache
        case unkeyed(UnkeyedDecodeElement)

        init(from value: JSONBValue) { self = .raw(value) }
        init(from data: Data) throws { try self.init(from: JSONBValue(from: data)) }

        init?(from value: JSONBValue?) {
            if let value { self = .raw(value) } else { return nil }
        }

        init?(from data: Data?) throws {
            if let data {
                try self.init(from: JSONBValue(from: data))
            } else {
                return nil
            }
        }

        var type: JSONBType {
            switch self {
                case let .raw(value): value.type
                case .unkeyed: .array
                case .keyed: .object
            }
        }

        func decodeNil() -> Bool {
            if case let .raw(value) = self { return value.type == .null }
            return false
        }

        func decode(for keyPath: CodingKeyPath) throws -> Bool? {
            if case let .raw(jsonb) = self { return try jsonb.decode(for: keyPath) }
            return nil
        }

        func decode(for keyPath: CodingKeyPath) throws -> Data? {
            if case let .raw(jsonb) = self { return try jsonb.decode(for: keyPath) }
            return nil
        }

        func decode(for keyPath: CodingKeyPath) throws -> Date? {
            if case let .raw(jsonb) = self { return try jsonb.decode(for: keyPath) }
            return nil
        }

        func decode(for keyPath: CodingKeyPath) throws -> Float? {
            if case let .raw(jsonb) = self { return try jsonb.decode(for: keyPath) }
            return nil
        }

        func decode(for keyPath: CodingKeyPath) throws -> Double? {
            if case let .raw(jsonb) = self { return try jsonb.decode(for: keyPath) }
            return nil
        }

        func decode(for keyPath: CodingKeyPath) throws -> String? {
            if case let .raw(jsonb) = self { return try jsonb.decode(for: keyPath) }
            return nil
        }

        func decode<T>(for keyPath: CodingKeyPath) throws -> T?
            where T: BinaryInteger & Decodable & LosslessStringConvertible
        {
            if case let .raw(jsonb) = self { return try jsonb.decode(for: keyPath) }
            return nil
        }

        var keyed: KeyedDecodeElement? {
            get throws {
                switch self {
                    case let .keyed(object): object
                    case let .raw(value): try KeyedDecodeElement(from: value)
                    default: nil
                }
            }
        }

        var unkeyed: UnkeyedDecodeElement? {
            get throws {
                switch self {
                    case let .unkeyed(array): array
                    case let .raw(value): try UnkeyedDecodeElement(from: value)
                    default: nil
                }
            }
        }
    }
}

// MARK: - Keyed

extension JSONB {
    /// Cache for `KeyedDecodingContainer` values
    ///
    /// Use of a reference type minimizes allocations
    class KeyedDecodeElement {
        #if DEBUG
        // ordered dictionary when debugging for consistent test expectations
        typealias DecodeValues = OrderedDictionary<String, DecodeElement?>
        #else
        typealias DecodeValues = [String: DecodeElement?]
        #endif
        private var values: DecodeValues
        var keys: any Sequence<String> { values.keys }
        var count: Int { values.count }

        subscript(key: String) -> DecodeElement? {
            get { values[key].flatMap(\.self) }
            set { values[key] = newValue }
        }

        subscript(key: some CodingKey) -> DecodeElement? {
            get { values[key.stringValue].flatMap(\.self) }
            set { values[key.stringValue] = newValue }
        }

        init(values: DecodeValues = [:]) {
            self.values = values
        }

        init?(from jsonb: JSONBValue) throws {
            if jsonb.type == .object {
                values = try jsonb.object.mapValues { DecodeElement(from: $0) }
            } else {
                return nil
            }
        }

        func contains(_ key: String) -> Bool { values.keys.contains(key) }
        func contains(_ key: some CodingKey) -> Bool { contains(key.stringValue) }

        func type(for key: String) -> JSONBType? { values[key].flatMap(\.self)?.type }
        func type(for key: some CodingKey) -> JSONBType? { type(for: key.stringValue) }

        func decodeNil(_ key: some CodingKey) -> Bool? { self[key]?.decodeNil() }

        func decode(_ key: some CodingKey, for keyPath: CodingKeyPath) throws -> Bool? {
            try self[key]?.decode(for: keyPath)
        }

        func decode(_ key: some CodingKey, for keyPath: CodingKeyPath) throws -> Data? {
            try self[key]?.decode(for: keyPath)
        }

        func decode(_ key: some CodingKey, for keyPath: CodingKeyPath) throws -> Date? {
            try self[key]?.decode(for: keyPath)
        }

//        func decode(_ key: some CodingKey, for keyPath: CodingKeyPath) throws -> UUID? {
//            try self[key]?.decode(for: keyPath)
//        }

        func decode(_ key: some CodingKey, for keyPath: CodingKeyPath) throws -> Float? {
            try self[key]?.decode(for: keyPath)
        }

        func decode(_ key: some CodingKey, for keyPath: CodingKeyPath) throws -> Double? {
            try self[key]?.decode(for: keyPath)
        }

        func decode(_ key: some CodingKey, for keyPath: CodingKeyPath) throws -> String? {
            try self[key]?.decode(for: keyPath)
        }

        func decode<T>(_ key: some CodingKey, for keyPath: CodingKeyPath) throws -> T?
            where T: BinaryInteger & Decodable & LosslessStringConvertible
        {
            try self[key]?.decode(for: keyPath)
        }

        func keyed(_ key: some CodingKey) throws -> KeyedDecodeElement? {
            if let value = self[key] { try value.keyed } else { nil }
        }

        func unkeyed(_ key: some CodingKey) throws -> UnkeyedDecodeElement? {
            if let value = self[key] { try value.unkeyed } else { nil }
        }
    }
}

// MARK: - Unkeyed

extension JSONB {
    /// Cache for `UnkeyedDecodingContainer` values
    ///
    /// Use of a reference type minimizes allocations
    class UnkeyedDecodeElement {
        private var values: [DecodeElement]

        subscript(index: Int) -> DecodeElement {
            get { values[index] }
            set { values[index] = newValue }
        }

        subscript(safe index: Int) -> DecodeElement? { values[safe: index] }

        var count: Int { values.count }

        init() {
            values = []
            values.reserveCapacity(10)
        }

        init?(from jsonb: JSONBValue) throws {
            if jsonb.type == .array {
                values = try jsonb.array.map { DecodeElement(from: $0) }
                return
            }
            return nil
        }

        func type(for index: Int) -> JSONBType? { values[safe: index]?.type }

        func decodeNil(at index: Int) -> Bool? { values[safe: index]?.decodeNil() }

        func decode(at index: Int, for keyPath: CodingKeyPath) throws -> Bool? {
            try values[safe: index]?.decode(for: keyPath)
        }

        func decode(at index: Int, for keyPath: CodingKeyPath) throws -> Data? {
            try values[safe: index]?.decode(for: keyPath)
        }

        func decode(at index: Int, for keyPath: CodingKeyPath) throws -> Date? {
            try values[safe: index]?.decode(for: keyPath)
        }

        func decode(at index: Int, for keyPath: CodingKeyPath) throws -> Float? {
            try values[safe: index]?.decode(for: keyPath)
        }

        func decode(at index: Int, for keyPath: CodingKeyPath) throws -> Double? {
            try values[safe: index]?.decode(for: keyPath)
        }

        func decode(at index: Int, for keyPath: CodingKeyPath) throws -> String? {
            try values[safe: index]?.decode(for: keyPath)
        }

        @available(*, unavailable)
        func decode<T>(at _: Int, for _: CodingKeyPath) throws -> T?
            where T: BinaryInteger & Decodable & LosslessStringConvertible
        {
            // if case let .raw(jsonb) = self { return try jsonb.decode(for: keyPath) }
            preconditionFailure("not implemented")
            // return nil
        }

        func keyed(at index: Int) throws -> KeyedDecodeElement? {
            if let value = values[safe: index] { try value.keyed } else { nil }
        }

        func unkeyed(at index: Int) throws -> UnkeyedDecodeElement? {
            if let value = values[safe: index] { try value.unkeyed } else { nil }
        }
    }
}
