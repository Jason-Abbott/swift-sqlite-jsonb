import Foundation

/// SQLite JSONB type and value as raw bytes
///
/// The payload may be a single value or it may be as-yet unparsed, additional `JSONBValue`s in an
/// object or array. In other words, until fully parsed, a `JSONBValue` may represent multiple
/// `JSONBValue`s.
///
/// ## Header Encoding and Decoding
///
/// The second four bits of the first byte indicate the type of payload. The first four bits
/// indicate the size of the payload in one of two ways:
///
/// - If payload data are between 0 and 11 bytes (inclusive), its size is a small enough number
///   to fit in the first four bits
/// - Otherwise, the size of the payload is encoded in the bytes *after* the first byte and the
///   the first 4 bits indicate the size of that size value
///
/// Only as many bytes as necessary are used to encode the payload size meaning it can vary from
/// 1 to 8 bytes (making total header size 2 to 9 bytes).
///
/// > Important: While Apple devices are little-endian, the JSONB format expects the payload size
///   to be encoded big-endian. (This does not affect numbers *within* the payload because they are
///   represented by their string values, not raw bytes.)
///
/// ![Bytes](JSONB+Format.pdf)
///
/// ## References
/// - [SQLite JSONB payload][1]
/// - [Serde JSONB serializer][2]
///
/// [1]: https://sqlite.org/jsonb.html#payload_size
/// [2]: https://github.com/zamazan4ik/serde-sqlite-jsonb
public struct JSONBValue {
    let type: JSONBType
    let payload: BytesView

    var isEmpty: Bool { payload.isEmpty }
    var endIndex: Int { payload.endIndex }
    var startIndex: Int { payload.startIndex }

    init(from buffer: BytesView) throws {
        if buffer.isEmpty { throw JSONBError.invalidHeader }

        let index = buffer.startIndex
        let firstByte = buffer[index]
        let rawType = firstByte & 0x0F

        guard let type = JSONBType(rawValue: rawType) else {
            throw JSONBError.unknownType(rawType)
        }
        self.type = type

        let sizeType = firstByte >> 4
        let sizeBytes = switch sizeType {
            case 0 ... 11: 0
            case 12: 1
            case 13: 2
            case 14: 4
            case 15: 8
            default: throw JSONBError.invalidSizeType(sizeType)
        }
        let payloadStart = index + 1 + sizeBytes // zero-based
        let payloadSize: Int = sizeBytes == 0
            ? Int(sizeType)
            : Int(unsignedBytes: buffer[index + 1 ..< payloadStart], order: .bigEndian)

        payload = buffer[payloadStart ..< payloadStart + payloadSize]
    }

    init(from data: Data) throws {
        try self.init(from: data.bytes[...])
    }

    private init() {
        type = .null
        payload = []
    }

    static var null: JSONBValue { Self() }

    /// Array of values within the payload or an empty array if the type is not an array
    var array: [JSONBValue] {
        get throws {
            guard type == .array else { return [] }
            var index = startIndex
            var values: [JSONBValue] = []

            while index < endIndex {
                let value = try JSONBValue(from: payload[index...])
                values.append(value)
                index = value.endIndex
            }

            return values
        }
    }

    #if DEBUG
    // ordered dictionary when debugging for consistent test expectations
    typealias Dictionary = OrderedDictionary<String, JSONBValue>
    #else
    typealias Dictionary = [String: JSONBValue]
    #endif

    /// Dictionary of values within the payload or an empty dictionary if the type is not an object
    var object: Self.Dictionary {
        get throws {
            guard type == .object else { return [:] }
            var index = startIndex
            var values: Self.Dictionary = [:]

            while index < endIndex - 1 {
                let key = try JSONBValue(from: payload[index...])
                let value = try JSONBValue(from: payload[key.endIndex...])

                index = value.endIndex
                try values[key.decode()] = value
            }

            return values
        }
    }
}

// MARK: - Support

public enum JSONBType: UInt8, Sendable {
    /// The element is JSON "null"
    case null = 0
    /// The element is JSON "true"
    case `true` = 1
    /// The element is JSON "false"
    case `false` = 2
    /// The element is a JSON integer value in the canonical RFC 8259 format
    case integer = 3
    /// The element is a JSON integer value that is not in the canonical format
    case int5 = 4
    /// The element is a JSON floating-point value in the canonical RFC 8259 format
    case float = 5
    /// The element is a JSON floating-point value that is not in the canonical format
    case float5 = 6
    /// The element is a JSON string value that does not contain any escapes
    case text = 7
    /// The element is a JSON string value that contains [RFC 8259][1] character escapes
    ///
    /// [1]: https://datatracker.ietf.org/doc/html/rfc8259#section-7
    case textJ = 8
    /// The element is a JSON string value that contains character escapes, including some from
    /// JSON5
    case text5 = 9
    /// The element is a JSON string value that contains UTF8 characters that need to be escaped
    case textRaw = 0xA
    /// The element is a JSON array
    case array = 0xB
    /// The element is a JSON object
    case object = 0xC
    /// Reserved for future expansion
    case reserved13 = 0xD
    /// Reserved for future expansion
    case reserved14 = 0xE
    /// Reserved for future expansion
    case reserved15 = 0xF
}

public enum JSONBError: Error {
    case invalidHeader
    case unknownType(UInt8)
    case invalidUTF8(BytesView)
    case unhandledType(JSONBType)
    case invalidSizeType(UInt8)
}
