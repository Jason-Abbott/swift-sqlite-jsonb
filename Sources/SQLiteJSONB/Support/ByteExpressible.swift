import Foundation

public protocol ByteExpressible {
    var bytes: Bytes { get }
}

extension Bool: ByteExpressible { public var bytes: Bytes { [self ? 0x01 : 0x00] }}
extension Data: ByteExpressible { public var bytes: Bytes { Bytes(self) }}
extension String: ByteExpressible { public var bytes: Bytes { Array(utf8) }}
extension Locale: ByteExpressible { public var bytes: Bytes { identifier.bytes }}
extension Character: ByteExpressible { public var bytes: Bytes { String(self).bytes }}

extension Optional: ByteExpressible where Wrapped: ByteExpressible {
    public var bytes: Bytes {
        if let value = self { value.bytes } else { [0] }
    }
}

// RawRepresentable enumerations will still need to conform to ByteExpressible since
// RawRepresentable cannot add its own conformance. However, the enumeration will not need to
// implement the bytes property.
public extension RawRepresentable where RawValue: ByteExpressible {
    var bytes: Bytes { rawValue.bytes }
}

extension Double: ByteExpressible {
    public var bytes: Bytes { withUnsafeBytes(of: self, Array.init) }
}

extension Int: ByteExpressible {}
