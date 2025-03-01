// public import GRDB
// import OSLog
//
// private let log = Logger.current
//
///// Type can be encoded to and decoded from a SQLite [JSONB][1] column
/////
///// [1]: https://sqlite.org/jsonb.html
// public protocol JSONBConvertible: Codable, DatabaseValueConvertible, Sendable {
//    static var jsonType: JSONType { get }
//    init?(json data: Data?)
// }
//
// public extension JSONBConvertible {
//    init?(json data: Data?) {
//        guard let data else { return nil }
//
//        do {
//            self = try Self(from: JSONBDecoder(from: data))
//        } catch {
//            log.error("Failed to JSONB decode \(data.bytes) as \(Self.Type.self): \(error)")
//            return nil
//        }
//    }
//
//    var jsonType: JSONType { Self.jsonType }
//
//    var databaseValue: DatabaseValue {
//        do {
//            return try JSONBEncoder.encode(self).databaseValue
//        } catch {
//            log.error("Failed to JSONB encode \(Self.Type.self) as Data")
//            return DatabaseValue.null
//        }
//    }
//
//    static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Self? {
//        if case let .blob(data) = dbValue.storage {
//            self.init(json: data)
//        } else {
//            nil
//        }
//    }
// }
