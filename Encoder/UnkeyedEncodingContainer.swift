extension JSONBEncoder {
    struct UnkeyedContainer: UnkeyedEncodingContainer {
        private let encoder: JSONBEncoder

        var count: Int { element.count }
        let element: JSONB.UnkeyedEncodeElement
        let keyPath: CodingKeyPath
        let userInfo: [CodingUserInfoKey: Any] = [:]
        var codingPath: [any CodingKey] { encoder.codingPath + keyPath.path }

        init(
            for encoder: JSONBEncoder,
            at keyPath: CodingKeyPath,
            with element: JSONB.UnkeyedEncodeElement
        ) {
            self.element = element
            self.encoder = encoder
            self.keyPath = keyPath
        }

        public func nestedContainer<NestedKey>(
            keyedBy _: NestedKey.Type
        ) -> KeyedEncodingContainer<NestedKey> {
            KeyedEncodingContainer(KeyedContainer<NestedKey>(
                for: encoder,
                at: keyPath.appending(index: count),
                with: element.appendedKeyed
            ))
        }

        public func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer {
            UnkeyedContainer(
                for: encoder,
                at: keyPath.appending(index: count),
                with: element.appendedUnkeyed
            )
        }

        func superEncoder() -> any Encoder {
            JSONBNestedEncoder(for: encoder, at: element.count, updating: element)
        }
    }
}

// MARK: - Encode Overloads

extension JSONBEncoder.UnkeyedContainer {
    func encodeNil() throws { element.append(JSONBValue.encodeNil()) }

    func encode(_ value: Bool) throws { element.append(JSONBValue.encode(value)) }
    func encode(_ value: String) throws { element.append(JSONBValue.encode(value)) }

    func encode(_ value: some (BinaryInteger & Encodable)) throws {
        element.append(JSONBValue.encode(value))
    }

    func encode(_ value: some Encodable) throws {
        let encoder = JSONBEncoder(for: encoder, at: element.count)
        try value.encode(to: encoder)
        element.append(encoder.bytes)
    }
}
