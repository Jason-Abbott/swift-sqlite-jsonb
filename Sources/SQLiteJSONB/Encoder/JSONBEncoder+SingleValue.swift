public import Foundation

extension JSONBEncoder: SingleValueEncodingContainer {
    private func store(_ value: Bytes) { element = .value(value) }

    public func encodeNil() throws { store(JSONBValue.encodeNil()) }
    public func encode(_ value: Bool) throws { store(JSONBValue.encode(value)) }
    public func encode(_ value: String) throws { store(JSONBValue.encode(value)) }

    public func encode(_ value: some (BinaryInteger & Encodable)) throws {
        store(JSONBValue.encode(value))
    }

    public func encode(_ value: Float) throws { store(JSONBValue.encode(value)) }
    public func encode(_ value: Double) throws { store(JSONBValue.encode(value)) }

    public func encode(_ value: some Encodable) throws {
        switch value {
            case let value as String: try encode(value)
            case let value as Bool: try encode(value)
            case let value as Int: try encode(value)
            case let value as Int8: try encode(value)
            case let value as Int16: try encode(value)
            case let value as Int32: try encode(value)
            case let value as Int64: try encode(value)
            case let value as UInt: try encode(value)
            case let value as UInt8: try encode(value)
            case let value as UInt16: try encode(value)
            case let value as UInt32: try encode(value)
            case let value as UInt64: try encode(value)
            case let value as Float: try encode(value)
            case let value as Double: try encode(value)
            case let value as Data: try encode(value)
            case let value as Date: try encode(value)
            default:
                try value.encode(to: self)
                store(bytes)
        }
    }
}

// MARK: - Custom encoders

// not SingleValueEncodingContainer conformance
extension JSONBEncoder {
    public func encode(_ value: Date) throws { store(JSONBValue.encode(value)) }
    public func encode(_ value: Data) throws { store(JSONBValue.encode(value)) }
}
