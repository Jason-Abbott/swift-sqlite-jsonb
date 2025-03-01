public import Foundation

public extension JSONBDecoder {
    internal convenience init(from data: Data, at key: CodingKeyPath = .root) throws {
        try self.init(from: JSONB.DecodeElement(from: data), at: key)
    }

    internal convenience init(from value: JSONBValue, at key: CodingKeyPath = .root) {
        self.init(from: JSONB.DecodeElement(from: value), at: key)
    }

//    @_disfavoredOverload
    static func decode<T>(_ data: Data) throws -> T where T: Decodable {
        try T(from: JSONBDecoder(from: data))
    }

    // more specific overload ensures use of CodableProvidingConfiguration
//    static func decode(_ data: Data) throws -> AttributedString {
//        try AttributedString(
//            from: JSONBDecoder(from: data),
//            configuration: AttributedString.decodingConfiguration
//        )
//    }

    static func decode<T>(_ jsonb: JSONBValue) throws -> T where T: Decodable {
        try T(from: JSONBDecoder(from: jsonb))
    }

//    static func decode<T>(
//        _ jsonb: JSONBValue
//    ) throws -> T where T: CodableProvidingConfiguration {
//        try T(from: JSONBDecoder(from: jsonb), configuration: T.decodingConfiguration)
//    }

    static func decode<T>(
        _ data: Data,
        configuration: T.DecodingConfiguration
    ) throws -> T where T: DecodableWithConfiguration {
        try T(from: JSONBDecoder(from: data), configuration: configuration)
    }

    static func decode<T>(
        _ jsonb: JSONBValue,
        configuration: T.DecodingConfiguration
    ) throws -> T where T: DecodableWithConfiguration {
        try T(from: JSONBDecoder(from: jsonb), configuration: configuration)
    }

    static func decode<T, C>(_ data: Data, configuration provider: C.Type) throws -> T
        where T: DecodableWithConfiguration,
        C: DecodingConfigurationProviding,
        T.DecodingConfiguration == C.DecodingConfiguration
    {
        try T(from: JSONBDecoder(from: data), configuration: provider.decodingConfiguration)
    }

    static func decode<T, C>(
        _ jsonb: JSONBValue,
        configuration provider: C.Type
    ) throws -> T
        where T: DecodableWithConfiguration,
        C: DecodingConfigurationProviding,
        T.DecodingConfiguration == C.DecodingConfiguration
    {
        try T(from: JSONBDecoder(from: jsonb), configuration: provider.decodingConfiguration)
    }
}
