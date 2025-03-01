public import Foundation

extension JSONBDecoder: SingleValueDecodingContainer {
    public func decodeNil() -> Bool { element?.decodeNil() ?? false }

    public func decode(_ type: Bool.Type) throws -> Bool {
        if let value: Bool = try element?.decode(for: keyPath) { return value }
        throw notFound(type)
    }

    public func decode(_ type: Float.Type) throws -> Float {
        if let value: Float = try element?.decode(for: keyPath) { return value }
        throw notFound(type)
    }

    public func decode(_ type: Double.Type) throws -> Double {
        if let value: Double = try element?.decode(for: keyPath) { return value }
        throw notFound(type)
    }

    public func decode(_ type: String.Type) throws -> String {
        if let value: String = try element?.decode(for: keyPath) { return value }
        throw notFound(type)
    }

    public func decode<T>(
        _: T.Type
    ) throws -> T where T: BinaryInteger & Decodable & LosslessStringConvertible {
        if let value: T = try element?.decode(for: keyPath) { return value }
        throw notFound(T.self)
    }

    public func decode<T: Decodable>(_: T.Type) throws -> T {
        if let element { return try T(from: JSONBDecoder(from: element, at: keyPath)) }
        throw notFound(T.self)
    }

    /// JSONBValue decoder will throw its own errors if invalid type -- this is only for missing
    func notFound<T>(_: T.Type) -> DecodingError {
        DecodingError.valueNotFound(T.self, DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "Missing expected \(T.self) value"
        ))
    }
}

// MARK: - Custom decoders

// not from SingleValueDecodingContainer
extension JSONBDecoder {
    public func decode(_ type: Data.Type) throws -> Data {
        if let value: Data = try element?.decode(for: keyPath) { return value }
        throw notFound(type)
    }

    public func decode(_ type: Date.Type) throws -> Date {
        if let value: Date = try element?.decode(for: keyPath) { return value }
        throw notFound(type)
    }
}
