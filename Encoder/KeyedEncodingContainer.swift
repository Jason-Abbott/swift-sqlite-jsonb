import Foundation

extension JSONBEncoder {
    struct KeyedContainer<Key>: KeyedEncodingContainerProtocol where Key: CodingKey {
        private var encoder: JSONBEncoder

        let element: JSONB.KeyedEncodeElement
        let keyPath: CodingKeyPath
        var userInfo: [CodingUserInfoKey: Any] = [:]
        var codingPath: [any CodingKey] { encoder.codingPath + keyPath.path }

        init(
            for encoder: JSONBEncoder,
            at keyPath: CodingKeyPath,
            with element: JSONB.KeyedEncodeElement
        ) {
            self.element = element
            self.encoder = encoder
            self.keyPath = keyPath
        }

        mutating func nestedUnkeyedContainer(forKey key: Key) -> any UnkeyedEncodingContainer {
            let nestedElement: JSONB.UnkeyedEncodeElement

            if let existing = element[key] {
                if case let .unkeyed(unkeyedElement) = existing {
                    nestedElement = unkeyedElement
                } else {
                    preconditionFailure("Encoding container already exists at \(key)")
                }
            } else {
                nestedElement = element.unkeyed(for: key)
            }

            return UnkeyedContainer(for: encoder, at: keyPath.appending(key), with: nestedElement)
        }

        mutating func nestedContainer<NestedKey>(
            keyedBy _: NestedKey.Type,
            forKey key: Key
        ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            let nestedElement: JSONB.KeyedEncodeElement

            if let existing = element[key] {
                if case let .keyed(keyedElement) = existing {
                    nestedElement = keyedElement
                } else {
                    preconditionFailure("Encoding container already exists at \(key)")
                }
            } else {
                nestedElement = element.keyed(for: key)
            }

            return KeyedEncodingContainer(KeyedContainer<NestedKey>(
                for: encoder,
                at: keyPath.appending(key),
                with: nestedElement
            ))
        }

        func superEncoder() -> any Encoder {
            JSONBNestedEncoder(for: encoder, at: AnyContainerKey.super, updating: element)
        }

        func superEncoder(forKey key: Key) -> any Encoder {
            JSONBNestedEncoder(for: encoder, at: key, updating: element)
        }
    }
}

// MARK: - Encode Overloads

extension JSONBEncoder.KeyedContainer {
    func encodeNil(forKey key: Key) { element.appendNil(for: key) }

    func encode(_ value: Bool, forKey key: Key) { element.append(value, for: key) }
    func encode(_ value: Data, forKey key: Key) { element.append(value, for: key) }
    func encode(_ value: Date, forKey key: Key) { element.append(value, for: key) }
    func encode(_ value: Float, forKey key: Key) { element.append(value, for: key) }
    func encode(_ value: Double, forKey key: Key) { element.append(value, for: key) }
    func encode(_ value: String, forKey key: Key) { element.append(value, for: key) }

    func encode(_ value: some (BinaryInteger & Encodable), forKey key: Key) throws {
        element.append(value, for: key)
    }

    /// Encode a complex type
    ///
    /// `AttributedStrings` here may always carry custom attributes, requiring the inclusion of
    /// configuration describing those attributes
    func encode(_ value: some Encodable, forKey key: Key) throws {
        let encoder = JSONBEncoder(for: encoder, at: key)

//        if let text = value as? AttributedString {
//            try text.encode(to: encoder, configuration: AttributedString.encodingConfiguration)
//        } else {
            try value.encode(to: encoder)
//        }

        element.append(encoder.bytes, for: key)
    }
}
