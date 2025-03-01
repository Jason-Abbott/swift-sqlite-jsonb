import Foundation

enum JSONB {
    /// Element bytes ready for JSONB encoding (addition of JSONB header)
    enum EncodeElement: ByteExpressible {
        /// `SingleValueEncodingContainer` cache
        case value(Bytes)
        /// `KeyedEncodingContainer` cache
        case keyed(KeyedEncodeElement)
        /// `UnkeyedEncodingContainer` cache
        case unkeyed(UnkeyedEncodeElement)

        var bytes: Bytes {
            switch self {
                case let .value(value): value
                case let .unkeyed(value): value.bytes
                case let .keyed(value): value.bytes
            }
        }

        /// Empty keyed element
        ///
        /// This is used as a safe fallback when a nested decoder has no result
        static func emptyKeyedElement() -> Self { .keyed(KeyedEncodeElement()) }

        func copy() -> Self {
            switch self {
                case let .value(bytes): return .value(bytes)
                case let .keyed(keyed): return .keyed(keyed)
                case let .unkeyed(unkeyed): return .unkeyed(unkeyed)
            }
        }
    }
}

// MARK: - Keyed

extension JSONB {
    /// Cache for `KeyedEncodingContainer` values
    ///
    /// Use of a reference type minimizes allocations
    class KeyedEncodeElement: ByteExpressible {
        private var values: [String: EncodeElement] = [:]

        subscript(key: String) -> EncodeElement? {
            get { values[key] }
            set { values[key] = newValue }
        }

        subscript(key: some CodingKey) -> EncodeElement? {
            get { values[key.stringValue] }
            set { values[key.stringValue] = newValue }
        }

        func append(_ value: Bytes, for key: some CodingKey) { self[key] = .value(value) }

        func appendNil(for key: some CodingKey) {
            append(JSONBValue.encodeNil(), for: key)
        }

        func append(_ value: Bool, for key: some CodingKey) {
            append(JSONBValue.encode(value), for: key)
        }

        func append(_ value: Data, for key: some CodingKey) {
            append(JSONBValue.encode(value), for: key)
        }

        func append(_ value: Date, for key: some CodingKey) {
            append(JSONBValue.encode(value), for: key)
        }

        func append(_ value: Float, for key: some CodingKey) {
            append(JSONBValue.encode(value), for: key)
        }

        func append(_ value: Double, for key: some CodingKey) {
            append(JSONBValue.encode(value), for: key)
        }

        func append(_ value: String, for key: some CodingKey) {
            append(JSONBValue.encode(value), for: key)
        }

        func append(_ value: some (BinaryInteger & Encodable), for key: some CodingKey) {
            append(JSONBValue.encode(value), for: key)
        }

        /// Retrieve keyed element at given key or create a new keyed element at the key
        ///
        /// Execution halts if there is already an *unkeyed* element at the key. An error is not
        /// thrown since this is used by encoding container methods that are not throwing.
        func keyed(for key: String) -> KeyedEncodeElement {
            switch values[key] {
                case let .keyed(value):
                    return value
                case .unkeyed:
                    preconditionFailure("Unkeyed container already created for \"\(key)\"")
                case .none, .value:
                    let value = KeyedEncodeElement()
                    values[key] = .keyed(value)
                    return value
            }
        }

        func keyed(for key: some CodingKey) -> KeyedEncodeElement {
            keyed(for: key.stringValue)
        }

        /// Retrieve unkeyed element at given key or create a new unkeyed element at the key
        ///
        /// Execution halts if there is already a *keyed* element at the key. An error is not thrown
        /// since this is used by encoding container methods that are not throwing.
        func unkeyed(for key: String) -> UnkeyedEncodeElement {
            switch values[key] {
                case let .unkeyed(value):
                    return value
                case .keyed:
                    preconditionFailure("Keyed container already created for \"\(key)\"")
                case .none, .value:
                    let value = UnkeyedEncodeElement()
                    values[key] = .unkeyed(value)
                    return value
            }
        }

        func unkeyed(for key: some CodingKey) -> UnkeyedEncodeElement {
            unkeyed(for: key.stringValue)
        }

        /// Encode values as a JSONB ``JSONBType/object``
        ///
        /// The values themselves must already be encoded (have a [JSONB header][1])
        ///
        /// [1]: https://sqlite.org/jsonb.html#payload_size
        var bytes: Bytes {
            var result = Bytes()

            #if DEBUG
            // sort keys when debugging for consistent test expectations
            for key in values.keys.sorted() {
                result += JSONBValue.encode(.text, with: key.bytes)
                result += values[key].bytes
            }
            #else
            for (key, element) in values {
                result += JSONBValue.encode(.text, with: key.bytes)
                result += element.bytes
            }
            #endif
            return JSONBValue.encode(.object, with: result)
        }
    }
}

// MARK: - Unkeyed

extension JSONB {
    /// Cache for `UnkeyedEncodingContainer` values
    ///
    /// Use of a reference type minimizes allocations
    class UnkeyedEncodeElement: ByteExpressible {
        private var values: [EncodeElement] = []

        subscript(index: Int) -> EncodeElement {
            get { values[index] }
            set { values[index] = newValue }
        }

        var count: Int { values.count }

        init() {
            values.reserveCapacity(10)
        }

        /// Append single value bytes to the array
        func append(_ value: Bytes) { values.append(.value(value)) }

        func appendNil() { append(JSONBValue.encodeNil()) }

        func append(_ value: Bool) { append(JSONBValue.encode(value)) }
        func append(_ value: Data) { append(JSONBValue.encode(value)) }
        func append(_ value: Date) { append(JSONBValue.encode(value)) }
        func append(_ value: Float) { append(JSONBValue.encode(value)) }
        func append(_ value: Double) { append(JSONBValue.encode(value)) }
        func append(_ value: String) { append(JSONBValue.encode(value)) }
        func append(_ value: some (BinaryInteger & Encodable)) { append(JSONBValue.encode(value)) }

        /// Create a nested array cache appended to the array
        var appendedUnkeyed: UnkeyedEncodeElement {
            let value = UnkeyedEncodeElement()
            values.append(.unkeyed(value))
            return value
        }

        /// Create an object cache appended to the array
        var appendedKeyed: KeyedEncodeElement {
            let value = KeyedEncodeElement()
            values.append(.keyed(value))
            return value
        }

        func insert(_ value: EncodeElement, at index: Int) { values.insert(value, at: index)
        }

        /// Encode values as a JSONB ``JSONBType/array``
        ///
        /// The values themselves must already be encoded (have a [JSONB header][1])
        ///
        /// [1]: https://sqlite.org/jsonb.html#payload_size
        var bytes: Bytes {
            JSONBValue.encode(.array, with: values.reduce(into: []) { bytes, element in
                bytes += element.bytes
            })
        }
    }
}
