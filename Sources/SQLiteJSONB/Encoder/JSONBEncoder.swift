public import Foundation

/// Swift standard encoder for the SQLite [JSONB format][1]
///
/// This follows the pattern of the Swift standard library [JSONEncoder][2]
///
/// ## References:
/// - MessagePack [encoder and decoder][3]
/// - Serde [JSONB serializer][4]
/// - Medium [How to create your own Encoder/Decoder in Swift][5]
///
/// [1]: https://sqlite.org/jsonb.html
/// [2]: https://github.com/swiftlang/swift-foundation/blob/main/Sources/FoundationEssentials/JSON/JSONEncoder.swift
/// [3]: https://github.com/Flight-School/MessagePack
/// [4]: https://github.com/zamazan4ik/serde-sqlite-jsonb
/// [5]: https://medium.com/codex/how-to-create-your-own-encoder-decoder-using-swift-cfe6a01ef3e7
public class JSONBEncoder: Encoder, ByteExpressible {
    /// The parent encoder if this instance was initialized by a container `superEncoder()` method
    ///
    /// > Developer Note: It is not clear what conditions suggest a "super encoder" (name seems
    ///   misleading) versus a nested container but see the AttributedString [source code][1] for
    ///   an example
    ///
    /// [1]: https://github.com/swiftlang/swift-foundation/blob/a0147acdc4e51255bbda829572f57ce110c0e663/Sources/FoundationEssentials/AttributedString/AttributedStringCodable.swift#L210
    private var parent: JSONBEncoder?

    var element: JSONB.EncodeElement?
    var codingKey: (any CodingKey)?
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    /// Traverse encoder ancestry (parents) to get the full key path to the current container
    public var codingPath: [any CodingKey] {
        var result = [any CodingKey]()
        var encoder = self

        if let codingKey { result.append(codingKey) }

        while let parent = encoder.parent, let key = parent.codingKey {
            result.append(key)
            encoder = parent
        }
        return result.reversed()
    }

    public init() {}

    init(for parent: JSONBEncoder, at key: (any CodingKey)?) {
        self.parent = parent
        codingKey = key
    }

    init(for parent: JSONBEncoder, at index: Int) {
        self.parent = parent
        codingKey = AnyContainerKey(index: index)
    }

    public func container<Key: CodingKey>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> {
        if case let .keyed(keyedElement) = element {
            let container = KeyedContainer<Key>(for: self, at: .root, with: keyedElement)
            return KeyedEncodingContainer(container)
        }
        guard element == nil else {
            preconditionFailure("Keyed encoding container already created at this path")
        }

        let keyedElement = JSONB.KeyedEncodeElement()
        let container = KeyedContainer<Key>(for: self, at: .root, with: keyedElement)
        element = .keyed(keyedElement)
        return KeyedEncodingContainer(container)
    }

    public func unkeyedContainer() -> any UnkeyedEncodingContainer {
        if case let .unkeyed(unkeyedElement) = element {
            return UnkeyedContainer(for: self, at: .root, with: unkeyedElement)
        }
        guard element == nil else {
            preconditionFailure("Unkeyed encoding container already created at this path")
        }
        let unkeyedElement = JSONB.UnkeyedEncodeElement()
        element = .unkeyed(unkeyedElement)
        return UnkeyedContainer(for: self, at: .root, with: unkeyedElement)
    }

    /// ## Discussion
    ///
    /// Like the Swift standard [JSONEncoder][1], this encoder is also the single value container
    ///
    /// [1]: https://github.com/swiftlang/swift-foundation/blob/79bd7e52e4876605fe26fccb5fb5bfc57041f191/Sources/FoundationEssentials/JSON/JSONEncoder.swift#L504
    public func singleValueContainer() -> any SingleValueEncodingContainer { self }

    public var bytes: Bytes { element?.bytes ?? [] }

    public var data: Data {
        // https://forums.swift.org/t/the-data-init-bytesnocopydeallocator-does-not-work-as-expected-when-data-is-of-representation-of-inlinedata/40996/7
        return Data(bytes)
//        if let container {
//            return Data(container.buffer)
        //            container.buffer.withUnsafeMutableBytes {
        //                Data(bytesNoCopy: $0.baseAddress!, count: $0.count, deallocator: .none)
        //            }

        //            return Data(
        //                bytesNoCopy: UnsafeMutableRawPointer(mutating: container.buffer),
        //                count: container.buffer.count,
        //                deallocator: .none
        //            )
//        }
    }
}

// MARK: - Support

extension Bytes {
    mutating func append(type: JSONBType) { append(type.rawValue) }
}
