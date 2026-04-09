import Foundation
import Testing
@testable import Core

struct JSONSchemaTests {
	private func encoder() -> JSONEncoder {
		JSONEncoder()
	}

	private func decoder() -> JSONDecoder {
		JSONDecoder()
	}

	@Test func withDescriptionReplacesExistingDescription() {
		let schema = JSONSchema.string(pattern: "abc", format: .email, description: "old")
		let updated = schema.withDescription("new")

		#expect(updated.description == "new")
		#expect(updated == .string(pattern: "abc", format: .email, description: "new"))
	}

	@Test func encodesNumberBoundsWithCorrectFieldOrder() throws {
		let schema = JSONSchema.number(
			multipleOf: 2,
			minimum: 10,
			exclusiveMinimum: 11,
			maximum: 20,
			exclusiveMaximum: 19,
			description: "range"
		)

		let data = try encoder().encode(schema)
		let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

		#expect(json["type"] as? String == "number")
		#expect(json["minimum"] as? Int == 10)
		#expect(json["exclusiveMinimum"] as? Int == 11)
		#expect(json["maximum"] as? Int == 20)
		#expect(json["exclusiveMaximum"] as? Int == 19)
	}

	@Test func decodesIntegerBoundsWithCorrectFieldOrder() throws {
		let data = Data(
			"""
			{
			  "type": "integer",
			  "multipleOf": 5,
			  "minimum": 15,
			  "exclusiveMinimum": 16,
			  "maximum": 25,
			  "exclusiveMaximum": 24,
			  "description": "integer-range"
			}
			""".utf8
		)

		let schema = try decoder().decode(JSONSchema.self, from: data)

		#expect(
			schema == .integer(
				multipleOf: 5,
				minimum: 15,
				exclusiveMinimum: 16,
				maximum: 25,
				exclusiveMaximum: 24,
				description: "integer-range"
			)
		)
	}
}
