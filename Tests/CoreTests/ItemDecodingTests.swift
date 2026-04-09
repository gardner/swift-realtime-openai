import Foundation
import Testing
@testable import Core

struct ItemDecodingTests {
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

	@Test func decodesMCPCAllAliasAsToolCall() throws {
		let data = Data(
			"""
			{
			  "type": "mcp_call",
			  "id": "item_123",
			  "server_label": "table_read",
			  "name": "find_screenplay_element",
			  "arguments": "{\\"query\\":\\"interest rates\\"}",
			  "output": "{\\"element_id\\":\\"s0027_e0005\\"}"
			}
			""".utf8
		)

		let item = try decoder().decode(Item.self, from: data)

		guard case let .mcpToolCall(toolCall) = item else {
			Issue.record("Expected mcp_call alias to decode as .mcpToolCall, got \(item)")
			return
		}

		#expect(toolCall.id == "item_123")
		#expect(toolCall.server == "table_read")
		#expect(toolCall.tool == "find_screenplay_element")
		#expect(toolCall.arguments == #"{"query":"interest rates"}"#)
	}

	@Test func decodesConversationItemAddedWithMCPCAllAlias() throws {
		let data = Data(
			"""
			{
			  "type": "conversation.item.added",
			  "event_id": "evt_123",
			  "previous_item_id": "item_prev",
			  "item": {
			    "type": "mcp_call",
			    "id": "item_123",
			    "server_label": "table_read",
			    "name": "find_screenplay_element",
			    "arguments": "{\\"query\\":\\"interest rates\\"}"
			  }
			}
			""".utf8
		)

		let event = try decoder().decode(ServerEvent.self, from: data)

		guard case let .conversationItemAdded(eventId, item, previousItemId) = event else {
			Issue.record("Expected conversation.item.added, got \(event)")
			return
		}

		#expect(eventId == "evt_123")
		#expect(previousItemId == "item_prev")

		guard case let .mcpToolCall(toolCall) = item else {
			Issue.record("Expected nested item to decode as .mcpToolCall, got \(item)")
			return
		}

		#expect(toolCall.tool == "find_screenplay_element")
	}

	@Test func encodesFunctionCallOutputWithItemType() throws {
		let item = Item.functionCallOutput(
			.init(id: "item_123", callId: "call_123", output: #"{"ok":true}"#)
		)

		let data = try encoder().encode(item)
		let json = try #require(String(data: data, encoding: .utf8))

		#expect(json.contains(#""type":"function_call_output""#))
		#expect(json.contains(#""call_id":"call_123""#))
		#expect(json.contains(#""output":"{\"ok\":true}""#))
	}
}
