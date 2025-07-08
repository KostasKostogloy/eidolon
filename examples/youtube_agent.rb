require 'eidolon'

class GetTranscriptionTool < Eidolon::Tool
  def initialize
    super(
      name: 'get_transcription',
      description: 'Retrieve the transcription of a YouTube video'
    )
  end

  def properties
    [
      Eidolon::ToolProperty.new(
        name: 'video_url',
        type: :string,
        description: 'The URL of the YouTube video',
        required: true
      )
    ]
  end

  def call(video_url:)
    "This is a mock transcription for video: #{video_url}"
  end
end

class YouTubeAgent < Eidolon::Agent
  def provider
    Eidolon::Providers::OpenRouter.new(
      api_key: ENV['OPENROUTER_API_KEY'],
      model: 'openai/gpt-4o'
    )
  end

  def instructions
    Eidolon::SystemPrompt.new(
      background: [
        "You are an AI Agent specialized in writing YouTube video summaries.",
        "You have access to tools that can help you retrieve video transcriptions."
      ],
      steps: [
        "Get the URL of a YouTube video from the user",
        "Use the get_transcription tool to retrieve the video transcription",
        "Write a concise summary of the video content"
      ],
      output_format: "Provide a clear, structured summary with key points and main takeaways."
    )
  end

  def tools
    [GetTranscriptionTool.new]
  end
end

# Usage example:
# agent = YouTubeAgent.new
# response = agent.chat("Please summarize this YouTube video: https://www.youtube.com/watch?v=example")
# puts response