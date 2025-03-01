public typealias Byte = UInt8
public typealias Bytes = [UInt8]

/// View into (or pointer to) a portion of a byte array
///
/// For additional features, consider use of SwiftNIO's [ByteBuffer][1]
///
/// [1]: https://github.com/apple/swift-nio/blob/main/Sources/NIOCore/ByteBuffer-core.swift
public typealias BytesView = ArraySlice<UInt8>

public extension BytesView {
    /// Convert a range of bytes to a `UInt64`
    var asUInt64: UInt64 { toInt() }
    /// Convert a range of bytes to a `UInt32`
    var asUInt32: UInt32 { toInt() }

    /// Convert bytes to an integer
    ///
    /// Compare to Swift [RawBufferPointer.load()][1]
    ///
    /// [1]: https://developer.apple.com/documentation/swift/unsaferawbufferpointer/load(frombyteoffset:as:)
    private func toInt<T: FixedWidthInteger>() -> T {
        var number: T = 0
        for i in 0 ..< MemoryLayout<T>.size { number |= T(self[startIndex + i]) << (i * 8) }
        return number
    }
}
