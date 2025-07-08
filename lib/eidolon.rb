require_relative "eidolon/version"
require_relative "eidolon/agent"
require_relative "eidolon/providers/openrouter"
require_relative "eidolon/providers/openai"
require_relative "eidolon/providers/anthropic"
require_relative "eidolon/providers/gemini"
require_relative "eidolon/message"
require_relative "eidolon/system_prompt"
require_relative "eidolon/tool"
require_relative "eidolon/tool_property"
require_relative "eidolon/structured_output"
require_relative "eidolon/attachment"

module Eidolon
  class Error < StandardError; end
  class StructuredOutputError < Error; end
end