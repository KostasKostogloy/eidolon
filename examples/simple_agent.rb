require 'eidolon'

class SimpleAgent < Eidolon::Agent
  def provider
    Eidolon::Providers::OpenRouter.new(
      api_key: ENV['OPENROUTER_API_KEY'],
      model: 'openai/gpt-4o'
    )
  end

  def instructions
    "You are a helpful assistant that answers questions clearly and concisely."
  end
end

# Usage example:
# agent = SimpleAgent.new
# response = agent.chat("What is the capital of France?")
# puts response