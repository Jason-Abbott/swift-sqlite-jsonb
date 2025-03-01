public extension FixedWidthInteger {
    /// ## References
    /// - [Swift forum topic][1]
    /// - Apple: [ArraySlice.withUnsafeBytes()][2]
    /// - [MessagePack Codable][3]
    ///
    /// [1]: https://forums.swift.org/t/convert-uint8-to-int/30117/3
    /// [2]: https://developer.apple.com/documentation/swift/arrayslice/withunsafebytes(_:)
    /// [3]: https://github.com/Flight-School/MessagePack/blob/master/Sources/MessagePack/FixedWidthInteger%2BBytes.swift
    init(bytes: Bytes) {
        self = bytes.withUnsafeBufferPointer {
            $0.baseAddress!.withMemoryRebound(to: Self.self, capacity: 1) { $0.pointee }
        }
    }

    init(bytes: BytesView) { self = .init(bytes: Array(bytes)) }

    var bytes: Bytes {
        var copy = self
        let capacity = MemoryLayout<Self>.size
        return withUnsafePointer(to: &copy) {
            $0.withMemoryRebound(to: UInt8.self, capacity: capacity) {
                Array(UnsafeBufferPointer(start: $0, count: capacity))
            }
        }
    }
}

public enum ByteOrder {
    case bigEndian
    case littleEndian
}

extension Int {
    /// Initialize integer from the smallest unsigned type the bytes can represent
    ///
    /// This is the difference, for example, between `x` and `y` given
    /// ```swift
    /// let bytes = [0x03, 0x1C]
    /// let x = Int(bytes: bytes)         // 224,054,081,461,682,176
    /// let y = Int(unsignedBytes: bytes) // 796
    /// ```
    init(unsignedBytes bytes: BytesView, order: ByteOrder = .littleEndian) {
        if order == .littleEndian {
            self = switch bytes.count {
                case 1: Int(UInt8(bytes: bytes))
                case 2: Int(UInt16(bytes: bytes))
                case 4: Int(UInt32(bytes: bytes))
                default: Int(bytes: bytes)
            }
        } else {
            self = switch bytes.count {
                case 1: Int(UInt8(bytes: bytes).bigEndian)
                case 2: Int(UInt16(bytes: bytes).bigEndian)
                case 4: Int(UInt32(bytes: bytes).bigEndian)
                default: Int(bytes: bytes).bigEndian
            }
        }
    }

    /// Initialize integer from the smallest unsigned type the bytes can represent
    ///
    /// This is the difference, for example, between `x` and `y` given
    /// ```swift
    /// let bytes = [0x03, 0x1C]
    /// let x = Int(bytes: bytes)         // 224,054,081,461,682,176
    /// let y = Int(unsignedBytes: bytes) // 796
    /// ```
    init(unsignedBytes bytes: Bytes, order: ByteOrder = .littleEndian) {
        self = .init(unsignedBytes: bytes[...], order: order)
    }
}
