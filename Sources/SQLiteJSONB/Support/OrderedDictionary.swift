/// A dictionary with guaranteed key ordering
///
/// This is a copy of GRDB [OrderedDictionary][1] used here only within a DEBUG condition
///
/// [1]: https://github.com/groue/GRDB.swift/blob/master/GRDB/Utils/OrderedDictionary.swift
public struct OrderedDictionary<Key: Hashable & Sendable, Value> {
    public private(set) var keys: [Key]
    private var dictionary: [Key: Value]

    /// Ordered values
    public var values: [Value] { keys.map { dictionary[$0]! } }

    private init(keys: [Key], dictionary: [Key: Value]) {
        assert(Set(keys) == Set(dictionary.keys))
        self.keys = keys
        self.dictionary = dictionary
    }

    public init() {
        keys = []
        dictionary = [:]
    }

    public init(minimumCapacity: Int) {
        keys = []
        keys.reserveCapacity(minimumCapacity)
        dictionary = Dictionary(minimumCapacity: minimumCapacity)
    }

    /// Returns the value associated with key, or `nil`
    public subscript(_ key: Key) -> Value? {
        get { dictionary[key] }
        set {
            if let value = newValue {
                updateValue(value, forKey: key)
            } else {
                removeValue(forKey: key)
            }
        }
    }

    /// Returns the value associated with key, or the default value
    public subscript(_ key: Key, default defaultValue: Value) -> Value {
        get { dictionary[key] ?? defaultValue }
        set { self[key] = newValue }
    }

    /// Appends the given value for the given key
    ///
    /// - precondition: There is no value associated with key yet.
    public mutating func appendValue(_ value: Value, forKey key: Key) {
        guard updateValue(value, forKey: key) == nil else {
            fatalError("key is already defined")
        }
    }

    /// Updates the value stored in the dictionary for the given key, or
    /// appends a new key-value pair if the key does not exist.
    ///
    /// Use this method instead of key-based subscripting when you need to know
    /// whether the new value supplants the value of an existing key. If the
    /// value of an existing key is updated, updateValue(_:forKey:) returns the
    /// original value. If the given key is not present in the dictionary, this
    /// method appends the key-value pair and returns nil.
    @discardableResult
    public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
        if let oldValue = dictionary.updateValue(value, forKey: key) {
            return oldValue
        }
        keys.append(key)
        return nil
    }

    /// Removes the value associated with key.
    @discardableResult
    public mutating func removeValue(forKey key: Key) -> Value? {
        guard let value = dictionary.removeValue(forKey: key) else {
            return nil
        }
        let index = keys.firstIndex { $0 == key }!
        keys.remove(at: index)
        return value
    }

    /// Returns a new ordered dictionary containing the keys of this dictionary
    /// with the values transformed by the given closure.
    public func mapValues<T>(
        _ transform: (Value) throws -> T
    ) rethrows -> OrderedDictionary<Key, T> {
        try reduce(into: .init()) { dict, pair in
            let value = try transform(pair.value)
            dict.appendValue(value, forKey: pair.key)
        }
    }

    /// Returns a new ordered dictionary containing only the key-value pairs
    /// that have non-nil values as the result of transformation by the
    /// given closure.
    public func compactMapValues<T>(
        _ transform: (Value) throws -> T?
    ) rethrows -> OrderedDictionary<Key, T> {
        try reduce(into: .init()) { dict, pair in
            if let value = try transform(pair.value) {
                dict.appendValue(value, forKey: pair.key)
            }
        }
    }

    public func filter(
        _ isIncluded: ((key: Key, value: Value)) throws -> Bool
    ) rethrows -> OrderedDictionary<Key, Value> {
        let dictionary = try dictionary.filter(isIncluded)
        let keys = keys.filter(dictionary.keys.contains)
        return OrderedDictionary(keys: keys, dictionary: dictionary)
    }

    public mutating func merge(
        with other: some Sequence<(Key, Value)>,
        uniquingKeysWith combine: (Value, Value) throws -> Value
    ) rethrows {
        for (key, value) in other {
            if let current = self[key] {
                self[key] = try combine(current, value)
            } else {
                self[key] = value
            }
        }
    }

    public mutating func merge(
        with other: some Sequence<(key: Key, value: Value)>,
        uniquingKeysWith combine: (Value, Value) throws -> Value
    ) rethrows {
        for (key, value) in other {
            if let current = self[key] {
                self[key] = try combine(current, value)
            } else {
                self[key] = value
            }
        }
    }

    public func merged(
        with other: some Sequence<(Key, Value)>,
        uniquingKeysWith combine: (Value, Value) throws -> Value
    ) rethrows -> OrderedDictionary<Key, Value> {
        var result = self
        try result.merge(with: other, uniquingKeysWith: combine)
        return result
    }

    public func merged(
        _ other: some Sequence<(key: Key, value: Value)>,
        uniquingKeysWith combine: (Value, Value) throws -> Value
    ) rethrows -> OrderedDictionary<Key, Value> {
        var result = self
        try result.merge(with: other, uniquingKeysWith: combine)
        return result
    }

    public func has(key: Key) -> Bool { keys.contains(key) }

    public mutating func sort(by areInIncreasingOrder: (Key, Key) -> Bool) {
        keys.sort(by: areInIncreasingOrder)
    }

    /// Sort keys so they match the order of the given keys
    public mutating func matchOrder(of otherKeys: [Key]) {
        func indexOf(_ key: Key) -> Int { otherKeys.firstIndex(of: key) ?? -1 }
        sort { k1, k2 in indexOf(k1) < indexOf(k2) }
    }

    /// Add values together
    ///
    /// Values on the right side of the equation will replace those on the left if they have the
    /// same key
    public static func + (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        for (key, value) in rhs { result[key] = value }
        return result
    }
}

extension OrderedDictionary: Sendable where Value: Sendable {}

extension OrderedDictionary: Collection {
    public typealias Index = Int

    public var startIndex: Int { 0 }
    public var endIndex: Int { keys.count }

    public func index(after i: Int) -> Int { i + 1 }

    public subscript(position: Int) -> (key: Key, value: Value) {
        let key = keys[position]
        return (key: key, value: dictionary[key]!)
    }
}

extension OrderedDictionary: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (Key, Value)...) {
        keys = elements.map(\.0)
        dictionary = Dictionary(uniqueKeysWithValues: elements)
    }
}

extension OrderedDictionary: Equatable where Value: Equatable {
    public static func == (lhs: OrderedDictionary, rhs: OrderedDictionary) -> Bool {
        (lhs.keys == rhs.keys) && (lhs.dictionary == rhs.dictionary)
    }
}

extension OrderedDictionary: CustomStringConvertible {
    public var description: String {
        let chunks = map { key, value in
            "\(String(reflecting: key)): \(String(reflecting: value))"
        }
        if chunks.isEmpty { return "[:]" }
        return "[\(chunks.joined(separator: ", "))]"
    }
}

public extension OrderedDictionary where Value: Sequence {
    var flatMap: [Value.Element] { values.flatMap(\.self) }
}

// MARK: - Array values

extension OrderedDictionary where Value: RangeReplaceableCollection {
    /// Add element to given key or create the key and assign a single element array value
    ///
    /// - Returns: Whether the key was updated rather than created
    @discardableResult
    mutating func append(_ element: Value.Element, to key: Key) -> Bool {
        if keys.contains(key) {
            dictionary[key]?.append(element)
            return true
        }
        self[key] = Value([element])
        return false
    }

    /// Add value element to all keys
    ///
    /// If any key does not exist then it will be created with the single element array as its value
    ///
    /// - Returns: Whether existing keys were updated
    @discardableResult
    mutating func append(_ element: Value.Element, to keys: [Key]?) -> Bool {
        guard let keys else { return false }
        var added = false
        for key in keys where append(element, to: key) { added = true }
        return added
    }
}
