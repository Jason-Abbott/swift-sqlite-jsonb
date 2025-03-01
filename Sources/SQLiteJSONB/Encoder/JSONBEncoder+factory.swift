public import Foundation

public extension JSONBEncoder {
//    @_disfavoredOverload
    static func encode(_ value: some Encodable) throws -> Data {
        let encoder = JSONBEncoder()
        try value.encode(to: encoder)
        return encoder.data
    }

//    static func encode<T: CodableProvidingConfiguration>(_ value: T) throws -> Data {
//        let encoder = JSONBEncoder()
//        try value.encode(to: encoder, configuration: T.encodingConfiguration)
//        return encoder.data
//    }

//    /// Encode an AttributedString
//    ///
//    /// Specific overload is needed in some contexts to ensure encoding configuration is applied
//    ///
//    /// ## References
//    /// - [AttributedString:Codable source][1]
//    ///
//    /// [1]: https://github.com/swiftlang/swift-foundation/blob/a0147acdc4e51255bbda829572f57ce110c0e663/Sources/FoundationEssentials/AttributedString/AttributedStringCodable.swift#L137
//    static func encode(_ value: AttributedString) throws -> Data {
//        let encoder = JSONBEncoder()
//        try value.encode(to: encoder, configuration: AttributedString.encodingConfiguration)
//        return encoder.data
//    }

    static func encode<T: EncodableWithConfiguration>(
        _ value: T,
        configuration: T.EncodingConfiguration
    ) throws -> Data {
        let encoder = JSONBEncoder()
        try value.encode(to: encoder, configuration: configuration)
        return encoder.data
    }

    static func encode<T, C>(
        _ value: T,
        configuration provider: C.Type
    ) throws -> Data where T: EncodableWithConfiguration, C: EncodingConfigurationProviding,
        T.EncodingConfiguration == C.EncodingConfiguration
    {
        let encoder = JSONBEncoder()
        try value.encode(to: encoder, configuration: provider.encodingConfiguration)
        return encoder.data
    }
}
