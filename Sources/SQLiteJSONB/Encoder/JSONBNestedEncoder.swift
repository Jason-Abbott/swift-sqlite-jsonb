/// Encoder created by a container `superEncoder()` method
///
/// > Note: It is not clear what conditions suggest a "super encoder" (name seems misleading)
///   versus a nested container but see the AttributedString [source code][1] for an example
///
/// [1]: https://github.com/swiftlang/swift-foundation/blob/a0147acdc4e51255bbda829572f57ce110c0e663/Sources/FoundationEssentials/Attribu
final class JSONBNestedEncoder: JSONBEncoder {
    private var container: ParentContainer

    init(for parent: JSONBEncoder, at index: Int, updating element: JSONB.UnkeyedEncodeElement) {
        container = .unkeyed(element, index)
        super.init(for: parent, at: index)
    }

    init(
        for parent: JSONBEncoder,
        at key: any CodingKey,
        updating element: JSONB.KeyedEncodeElement
    ) {
        container = .keyed(element, key.stringValue)
        super.init(for: parent, at: key)
    }

    deinit {
        defer { element = nil }

        let value = element?.copy() ?? .emptyKeyedElement()

        switch self.container {
            case let .keyed(containerElement, key):
                containerElement[key] = value
            case let .unkeyed(containerElement, index):
                containerElement.insert(value, at: index)
        }
    }

    private enum ParentContainer {
        case keyed(JSONB.KeyedEncodeElement, String)
        case unkeyed(JSONB.UnkeyedEncodeElement, Int)
    }
}
