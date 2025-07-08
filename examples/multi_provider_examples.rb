require 'eidolon'

# Example using OpenAI provider
class OpenAIAgent < Eidolon::Agent
  def provider
    Eidolon::Providers::OpenAI.new(
      api_key: ENV['OPENAI_API_KEY'],
      model: 'gpt-4o',
      organization: ENV['OPENAI_ORGANIZATION'] # optional
    )
  end

  def instructions
    "You are a helpful assistant powered by OpenAI."
  end
end

# Example using Anthropic provider
class AnthropicAgent < Eidolon::Agent
  def provider
    Eidolon::Providers::Anthropic.new(
      api_key: ENV['ANTHROPIC_API_KEY'],
      model: 'claude-3-5-sonnet-20241022',
      max_tokens: 4096
    )
  end

  def instructions
    "You are Claude, a helpful assistant made by Anthropic."
  end
end

# Example using Gemini provider
class GeminiAgent < Eidolon::Agent
  def provider
    Eidolon::Providers::Gemini.new(
      api_key: ENV['GEMINI_API_KEY'],
      model: 'gemini-1.5-pro-002'
    )
  end

  def instructions
    "You are Gemini, a helpful assistant made by Google."
  end
end

# Example using OpenRouter provider (original)
class OpenRouterAgent < Eidolon::Agent
  def provider
    Eidolon::Providers::OpenRouter.new(
      api_key: ENV['OPENROUTER_API_KEY'],
      model: 'openai/gpt-4o',
      site_url: 'https://myapp.com',
      site_name: 'My App'
    )
  end

  def instructions
    "You are a helpful assistant powered by OpenRouter."
  end
end

# Tool that works with all providers
class CalculatorTool < Eidolon::Tool
  def initialize
    super(
      name: 'calculator',
      description: 'Perform basic arithmetic calculations'
    )
  end

  def properties
    [
      Eidolon::ToolProperty.new(
        name: 'operation',
        type: :string,
        description: 'The operation to perform: add, subtract, multiply, divide',
        required: true
      ),
      Eidolon::ToolProperty.new(
        name: 'a',
        type: :number,
        description: 'First number',
        required: true
      ),
      Eidolon::ToolProperty.new(
        name: 'b',
        type: :number,
        description: 'Second number',
        required: true
      )
    ]
  end

  def call(operation:, a:, b:)
    case operation
    when 'add'
      a + b
    when 'subtract'
      a - b
    when 'multiply'
      a * b
    when 'divide'
      return "Error: Division by zero" if b == 0
      a / b
    else
      "Error: Unknown operation"
    end
  end
end

# Agent with tools that works with any provider
class MathAgent < Eidolon::Agent
  def provider
    # You can switch between providers easily
    Eidolon::Providers::OpenAI.new(
      api_key: ENV['OPENAI_API_KEY'],
      model: 'gpt-4o'
    )
  end

  def instructions
    Eidolon::SystemPrompt.new(
      background: "You are a math assistant with access to a calculator tool.",
      steps: [
        "Listen to the user's math problem",
        "Use the calculator tool to perform calculations",
        "Provide the result in a clear format"
      ]
    )
  end

  def tools
    [CalculatorTool.new]
  end
end

# Usage examples:
# 
# # Using different providers
# openai_agent = OpenAIAgent.new
# anthropic_agent = AnthropicAgent.new
# gemini_agent = GeminiAgent.new
# openrouter_agent = OpenRouterAgent.new
# 
# # All agents work the same way
# response = openai_agent.chat("Hello!")
# puts "OpenAI: #{response}"
# 
# response = anthropic_agent.chat("Hello!")
# puts "Anthropic: #{response}"
# 
# response = gemini_agent.chat("Hello!")
# puts "Gemini: #{response}"
# 
# response = openrouter_agent.chat("Hello!")
# puts "OpenRouter: #{response}"
# 
# # Using tools with any provider
# math_agent = MathAgent.new
# response = math_agent.chat("What is 15 * 23?")
# puts "Math result: #{response}"