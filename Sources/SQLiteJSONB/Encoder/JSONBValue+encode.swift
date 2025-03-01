import Foundation

extension JSONBValue {
    /// Add standard SQLite [JSONB header][1] to the payload
    ///
    /// ![Bytes](JSONB+Format.pdf)
    ///
    /// [1]: https://sqlite.org/jsonb.html#payload_size
    static func encode(_ type: JSONBType, with payload: Bytes) -> Bytes {
        var firstByte = type.rawValue
        /// Size of payload represented as bytes if too large to fit within 4 bits (meaning payload
        /// is greater than 11 bytes)
        let sizeBytes: Bytes
        let payloadSize = payload.count

        if payloadSize <= 11 {
            // payload size fits within four bits alongside the type in the first byte
            // shift size bits and combine (OR) with type value
            firstByte |= (UInt8(payloadSize) << 4)
            sizeBytes = []
        } else if payloadSize <= 0xFF {
            // this and following cases require additional bytes to store the payload size
            firstByte |= 0xC0
            sizeBytes = UInt8(payloadSize).bigEndian.bytes
        } else if payloadSize <= 0xFFFF {
            firstByte |= 0xD0
            sizeBytes = UInt16(payloadSize).bigEndian.bytes
        } else if payloadSize <= 0xFFFF_FFFF {
            firstByte |= 0xE0
            sizeBytes = UInt32(payloadSize).bigEndian.bytes
        } else {
            firstByte |= 0xF0
            sizeBytes = payloadSize.bigEndian.bytes
        }

        return [firstByte] + sizeBytes + payload
    }

    /// Add standard SQLite JSONB header to the payload
    private static func encode(_ type: JSONBType, with payload: some ByteExpressible) -> Bytes {
        encode(type, with: payload.bytes)
    }

    /// Encode integer bytes
    ///
    /// The JSONB specification stores the *display* value of numbers rather than raw bytes
    /// constituting the number.
    ///
    /// For example, the number `1` is stored as `0x31` (the ASCII value for the character `1`)
    /// rather than `0x01` (the raw byte value for the number `1`).
    static func encode(_ value: some BinaryInteger) -> Bytes {
        encode(.integer, with: String(value))
    }

    /// Encode floating point number
    ///
    /// If the number is actually an integer (has no decimals) then encode it as such. This is not
    /// explicitly [documented][1] except, perhaps, in the statement that the "shortest encoding
    /// is preferred." Tests, however, show this is the SQLite behavior.
    ///
    /// [1]: https://sqlite.org/jsonb.html#payload_size
    static func encode(_ value: Float) -> Bytes {
        if let number = Int(exactly: value) {
            encode(number)
        } else {
            encode(.float, with: String(value))
        }
    }

    /// Encode double value as floating point number
    ///
    /// If the number is actually an integer (has no decimals) then encode it as such. This is not
    /// explicitly [documented][1] except, perhaps, in the statement that the "shortest encoding
    /// is preferred." Tests, however, show this is the SQLite behavior.
    ///
    /// [1]: https://sqlite.org/jsonb.html#payload_size
    static func encode(_ value: Double) -> Bytes {
        if let number = Int(exactly: value) {
            encode(number)
        } else {
            encode(.float, with: String(value))
        }
    }

    static func encode(_ value: String) -> Bytes { encode(.text, with: value) }

    /// Encode date as an [ISO 8601][1] string
    ///
    /// Dates are encoded as strings rather than timestamps to ensure accuracy and improve
    /// readability
    ///
    /// ## References
    /// - [GRDB discussion][2]
    ///
    /// [1]: https://www.iso.org/iso-8601-date-and-time-format.html
    /// [2]: https://github.com/groue/GRDB.swift/issues/492
    static func encode(_ value: Date) -> Bytes { encode(value.ISO8601Format()) }

    static func encode(_ value: Data) -> Bytes { encode(value.base64EncodedString()) }

    static func encode(_ value: Bool) -> Bytes {
        value ? [JSONBType.true.rawValue] : [JSONBType.false.rawValue]
    }

    /// Encode UUID
    ///
    /// SQLite database triggers use [JSON][1] functions to retrieve these values and the [hex][2]
    /// function to parse them as `BLOB`s that may be matched to primary keys. Encoding this way
    /// is required for that usage.
    ///
    /// [1]: https://www.sqlite.org/json1.html
    /// [2]: https://www.sqlite.org/lang_corefunc.html#hex
//    static func encode(_ value: UUID) -> Bytes { encode(value.hexString) }

    static func encode<T: RawRepresentable>(_ value: T) -> Bytes where T.RawValue == String {
        encode(value.rawValue)
    }

    static func encode<T: RawRepresentable>(_ value: T) -> Bytes where T.RawValue: BinaryInteger {
        encode(value.rawValue)
    }

    static func encode(_ value: some CodingKey) -> Bytes { encode(value.stringValue) }

    static func encodeNil() -> Bytes { [JSONBType.null.rawValue] }
}
