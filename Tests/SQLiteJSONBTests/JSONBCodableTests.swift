import Foundation
import SQLiteJSONB
import Testing

struct JSONBCodableTests {
    // SQLite example
    // https://sqlite.org/jsonb.html#payload_size
    @Test func encodeInt() throws {
        let value = try #require(try JSONBEncoder.encode(1))
        #expect(value == Data([0x13, 0x31]))
    }

    @Test func decodeInt() throws {
        let number: Int = try JSONBDecoder.decode(Data([0x13, 0x31]))
        #expect(number == 1)
    }

//    @Test func encodeObject() async throws {
//        try expectJSON(Self.objectValue, encodesTo: Self.objectData)
//        try await expectJSON(Self.objectValue, encodesTo: Self.objectJSON)
//    }

//    @Test func encodeNestedObject() async throws {
//        let thing = Outer(some: "Some", things: [Self.objectValue, Self.objectValue])
//        let json = "{\"some\":\"Some\",\"things\":[\(Self.objectJSON),\(Self.objectJSON)]}"
//        try await expectJSON(thing, encodesTo: json)
//    }
//
//    @Test func decodeObject() throws {
//        try expectJSON(Self.objectData, decodesTo: Self.objectValue)
//    }
//
//    @Test func encodeArray() throws {
//        try expectJSON(Self.arrayValue, encodesTo: Self.arrayData)
//    }
//
//    @Test func decodeArray() throws {
//        try expectJSON(Self.arrayData, decodesTo: Self.arrayValue)
//    }

//    // There is a threshold at ten AttributedString runs to use a different structure
//    // https://github.com/swiftlang/swift-foundation/blob/e43505ce4a97177c40d0b8e5c1751e4cc4142b0c/Sources/FoundationEssentials/AttributedString/AttributedStringCodable.swift#L181
//    @Test func codableManyStyledAttributedString() async throws {
//        let text = AttributedString {
//            "One "
//            "Two".having { $0.bold() }
//            " Three "
//            "Four".having { $0.italics() }
//            " Five "
//            "Six".having { $0.note(UUID()) }
//            " Seven "
//            "Eight".having { $0.superscript() }
//            " Nine "
//            "Ten".having { $0.subscript() }
//            " Eleven "
//            "Twelve".having { $0.prevent(.bold) }
//        }
//        try await expectEncodesValidJSON(text)
//    }
//
//    @Test func codableStructureWithAttributedString() async throws {
//        let fields = ReferenceFields(text: [
//            .note: AttributedString("test note"),
//            .title: AttributedString {
//                "One "
//                "Two".having { $0.bold() }
//                " Three "
//                "Four".having { $0.italics() }
//                " Five "
//                "Six".having { $0.note(UUID()) }
//                " Seven "
//                "Eight".having { $0.superscript() }
//                " Nine "
//                "Ten".having { $0.subscript() }
//                " Eleven "
//                "Twelve".having { $0.prevent(.bold) }
//            },
//        ])
//        try await expectEncodesValidJSON(fields)
//    }

//    @Test func codableEmoji() async throws {
//        try await expectEncodesValidJSON(AttributedString {
//            "One 😀"
//            "Two".having { $0.bold() }
//        })
//    }
//
//    @Test func codableLongAttributedString() async throws {
//        try await expectEncodesValidJSON(AttributedString(
//            "Paragraph one voluptate sequi mollitia nostrum et sit perspiciatis enim assumenda qui minima eveniet. Eum qui et deserunt vel explicabo repellat illo ut reprehenderit tenetur deleniti eius est. Aut non voluptatem consectetur aperiam ex et numquam molestiae veniam est esse qui illum omnis ullam. Pariatur sed qui voluptas tempora occaecati fuga quia nihil. Libero molestiae asperiores praesentium ut fugit sed aliquam amet nihil qui sit exercitationem tempore odio veritatis. Consequatur porro sint qui facere nostrum amet laboriosam quia aut. Libero nobis quisquam voluptate voluptatum enim iusto commodi ipsam sed officia. Vel qui in eius quam aut velit quidem veritatis voluptas odit repudiandae eaque. Quia porro possimus atque numquam deleniti animi consequatur qui est enim vero laboriosam."
//        ))
//    }
//
//    @Test func codableEmptyAttributedString() async throws {
//        try await expectEncodesValidJSON(AttributedString(""))
//    }
//
//    @Test(.bug("https://github.com/toba/thesis/issues/171"))
//    func codableCustomType() async throws {
//        let value = FigureConfiguration(type: .jpeg, storageSize: 10)
//        try await expectEncodesValidJSON(value)
//    }
}

// MARK: - Fixtures

extension JSONBCodableTests {
    /// Serde example
    // https://github.com/zamazan4ik/serde-sqlite-jsonb?tab=readme-ov-file#example
    struct Simple: Encodable, Decodable, Equatable {
        let a: Bool
        let b: Bool
    }

    struct Outer: Encodable, Decodable, Equatable {
        let some: String
        let things: [Simple]
    }

    static let arrayValue = [0.25, 0.5, 0.5, 1]
    static let arrayData = Data([
        0xCB, // array type (0xB)
        0x0F, // size
        0x45, // size plus type (5)
        0x30, // 0
        0x2E, // .
        0x32, // 2
        0x35, // 5
        0x35, // float type (5)
        0x30, // 0
        0x2E, // .
        0x35, // 5
        0x35, // float type (5)
        0x30, // 0
        0x2E, // .
        0x35, // 5
        0x13, // integer type (1)
        0x31, // 1
    ])

    static let objectValue = Simple(a: false, b: true)
    static let objectJSON = #"{"a":false,"b":true}"#
    static let objectData = Data([0x6C, 0x17, 0x61, 0x02, 0x17, 0x62, 0x01])
}
