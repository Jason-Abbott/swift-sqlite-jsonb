/// Coding key for any container type
///
/// This is adapted from Swift foundation [_CodingKey][1]
///
/// [1]: https://github.com/swiftlang/swift-foundation/blob/79bd7e52e4876605fe26fccb5fb5bfc57041f191/Sources/FoundationEssentials/CodableUtilities.swift#L82
enum AnyContainerKey: CodingKey {
    case string(String)
    case int(Int)
    case index(Int)
    case both(String, Int)

    public init?(stringValue: String) {
        self = .string(stringValue)
    }

    public init?(intValue: Int) {
        self = .int(intValue)
    }

    init(index: Int) {
        self = .index(index)
    }

    init(stringValue: String, intValue: Int?) {
        if let intValue {
            self = .both(stringValue, intValue)
        } else {
            self = .string(stringValue)
        }
    }

    var stringValue: String {
        switch self {
            case let .string(str): return str
            case let .int(int): return "\(int)"
            case let .index(index): return "Index \(index)"
            case let .both(str, _): return str
        }
    }

    var intValue: Int? {
        switch self {
            case .string: return nil
            case let .int(int): return int
            case let .index(index): return index
            case let .both(_, int): return int
        }
    }

    static let `super` = AnyContainerKey.string("super")
}

/// Coding key path representations, whether keyed, indexed, root or "super"
///
/// This is adapted from Swift foundation [_CodingPathNode][1]
///
/// [1]: https://github.com/swiftlang/swift-foundation/blob/79bd7e52e4876605fe26fccb5fb5bfc57041f191/Sources/FoundationEssentials/CodableUtilities.swift#L26
enum CodingKeyPath: Sendable {
    case root
    indirect case key(any CodingKey, CodingKeyPath, depth: Int)
    indirect case index(Int, CodingKeyPath, depth: Int)

    var path: [any CodingKey] {
        switch self {
            case .root:
                return []
            case let .key(key, parent, _):
                return parent.path + [key]
            case let .index(index, parent, _):
                return parent.path + [AnyContainerKey(index: index)]
        }
    }

    var depth: Int {
        switch self {
            case .root: return 0
            case let .key(_, _, depth), let .index(_, _, depth): return depth
        }
    }

    func appending(_ key: (some CodingKey)?) -> CodingKeyPath {
        if let key { return .key(key, self, depth: depth + 1) }
        return self
    }

    func path(byAppending key: (some CodingKey)?) -> [any CodingKey] {
        if let key { return path + [key] }
        return path
    }

    func appending(index: Int) -> CodingKeyPath {
        .index(index, self, depth: depth + 1)
    }

    func path(byAppendingIndex index: Int) -> [any CodingKey] {
        path + [AnyContainerKey(index: index)]
    }
}
