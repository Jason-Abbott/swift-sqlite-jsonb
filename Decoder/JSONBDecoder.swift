/// Swift standard decoder for the SQLite [JSONB format][1]
///
/// ## References:
/// - [MessagePack encoder and decoder][2]
/// - [Serde JSONB serializer][3]
/// - "[How to create your own Encoder/Decoder in Swift][4]"
///
/// [1]: https://sqlite.org/jsonb.html
/// [2]: https://github.com/Flight-School/MessagePack
/// [3]: https://github.com/zamazan4ik/serde-sqlite-jsonb
/// [4]: https://medium.com/codex/how-to-create-your-own-encoder-decoder-using-swift-cfe6a01ef3e7
public class JSONBDecoder: Decoder {
    var element: JSONB.DecodeElement?
    var keyPath: CodingKeyPath
    public let userInfo: [CodingUserInfoKey: Any] = [:]
    public var codingPath: [any CodingKey] { keyPath.path }

    init(from element: JSONB.DecodeElement, at keyPath: CodingKeyPath) {
        self.element = element
        self.keyPath = keyPath
    }

    public func container<Key>(keyedBy _: Key.Type) throws -> KeyedDecodingContainer<Key>
        where Key: CodingKey
    {
        if let keyedElement = try element?.keyed {
            return try KeyedDecodingContainer(
                KeyedContainer(for: self, at: keyPath, with: keyedElement)
            )
        }
        throw notFound(JSONB.KeyedDecodeElement.self)
    }

    public func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        if let unkeyedElement = try element?.unkeyed {
            return UnkeyedContainer(for: self, at: keyPath, with: unkeyedElement)
        }
        throw notFound(JSONB.UnkeyedDecodeElement.self)
    }

    public func singleValueContainer() -> any SingleValueDecodingContainer { self }
}
