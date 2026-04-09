import Foundation
import Testing
@testable import Core

struct ToolCodingTests {
	private func decoder() -> JSONDecoder {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		return decoder
	}

	private func encoder() -> JSONEncoder {
		let encoder = JSONEncoder()
		encoder.keyEncodingStrategy = .convertToSnakeCase
		return encoder
	}

	@Test func decodesMCPToolChoiceWithServerLabel() throws {
		let data = Data(
			"""
			{
			  "type": "mcp",
			  "server_label": "table_read",
			  "name": "find_screenplay_element"
			}
			""".utf8
		)

		let choice = try decoder().decode(Tool.Choice.self, from: data)

		#expect(choice == .mcp(server: "table_read", tool: "find_screenplay_element"))
	}

	@Test func encodesMCPToolChoiceWithServerLabel() throws {
		let choice = Tool.Choice.mcp(server: "table_read", tool: "find_screenplay_element")

		let data = try encoder().encode(choice)
		let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

		#expect(json["type"] as? String == "mcp")
		#expect(json["server_label"] as? String == "table_read")
		#expect(json["name"] as? String == "find_screenplay_element")
	}

	@Test func decodesFlatMCPToolWithSnakeCaseFields() throws {
		let data = Data(
			"""
			{
			  "type": "mcp",
			  "server_label": "table_read",
			  "server_url": "https://example.com/mcp",
			  "allowed_tools": ["find_screenplay_element", "add_note"],
			  "headers": { "Authorization": "Bearer token" },
			  "require_approval": {
			    "always": { "tool_names": ["add_note"] },
			    "never": { "tool_names": ["find_screenplay_element"] }
			  },
			  "server_description": "Screenplay tools"
			}
			""".utf8
		)

		let tool = try decoder().decode(Tool.self, from: data)

		guard case let .mcp(mcp) = tool else {
			Issue.record("Expected .mcp tool, got \(tool)")
			return
		}

		#expect(mcp.label == "table_read")
		#expect(mcp.url == URL(string: "https://example.com/mcp"))
		#expect(mcp.allowedTools == ["find_screenplay_element", "add_note"])
		#expect(mcp.description == "Screenplay tools")
		#expect(
			mcp.requireApproval == .granular(
				always: ["add_note"],
				never: ["find_screenplay_element"]
			)
		)
	}

	@Test func encodesGranularRequireApprovalWithToolNames() throws {
		let tool = Tool.mcp(
			.init(
				label: "table_read",
				url: URL(string: "https://example.com/mcp")!,
				allowedTools: ["find_screenplay_element"],
				requireApproval: .granular(always: ["add_note"], never: ["find_screenplay_element"]),
				description: "Screenplay tools"
			)
		)

		let data = try encoder().encode(tool)
		let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
		let requireApproval = try #require(json["require_approval"] as? [String: Any])
		let always = try #require(requireApproval["always"] as? [String: Any])
		let never = try #require(requireApproval["never"] as? [String: Any])

		#expect(json["type"] as? String == "mcp")
		#expect(json["server_label"] as? String == "table_read")
		#expect(json["allowed_tools"] as? [String] == ["find_screenplay_element"])
		#expect(always["tool_names"] as? [String] == ["add_note"])
		#expect(never["tool_names"] as? [String] == ["find_screenplay_element"])
	}
}
