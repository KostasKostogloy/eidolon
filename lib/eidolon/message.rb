module Eidolon
  class Message
    attr_reader :role, :content
    
    def initialize(role:, content:)
      @role = role
      @content = content
    end
    
    def to_hash
      {
        role: @role,
        content: @content
      }
    end
  end
  
  class UserMessage < Message
    attr_reader :attachments
    
    def initialize(content:, attachments: [])
      super(role: "user", content: content)
      @attachments = attachments
    end
    
    def add_attachment(attachment)
      @attachments << attachment
      self
    end
    
    def has_attachments?
      !@attachments.empty?
    end
    
    def to_hash(provider_type: :openai)
      if has_attachments?
        to_hash_with_attachments(provider_type)
      else
        super()
      end
    end
    
    private
    
    def to_hash_with_attachments(provider_type)
      case provider_type
      when :openai, :openrouter
        to_openai_format
      when :anthropic
        to_anthropic_format
      when :gemini
        to_gemini_format
      else
        super()
      end
    end
    
    def to_openai_format
      content_parts = []
      
      # Add text content if present
      content_parts << { type: "text", text: @content } if @content && !@content.empty?
      
      # Add attachments
      @attachments.each do |attachment|
        if attachment.is_a?(Image)
          content_parts << attachment.to_openai_format
        else
          # OpenAI has limited document support
          content_parts << { type: "text", text: "[Document: #{attachment.filename || 'Unknown'}]" }
        end
      end
      
      {
        role: @role,
        content: content_parts
      }
    end
    
    def to_anthropic_format
      content_parts = []
      
      # Add text content if present
      content_parts << { type: "text", text: @content } if @content && !@content.empty?
      
      # Add attachments
      @attachments.each do |attachment|
        if attachment.is_a?(Image)
          content_parts << attachment.to_anthropic_format
        elsif attachment.is_a?(Document)
          content_parts << attachment.to_anthropic_format
        end
      end
      
      {
        role: @role,
        content: content_parts
      }
    end
    
    def to_gemini_format
      parts = []
      
      # Add text content if present
      parts << { text: @content } if @content && !@content.empty?
      
      # Add attachments
      @attachments.each do |attachment|
        if attachment.is_a?(Image) || attachment.is_a?(Document)
          parts << attachment.to_gemini_format
        end
      end
      
      {
        role: "user",
        parts: parts
      }
    end
  end
  
  class AssistantMessage < Message
    attr_reader :tool_calls
    
    def initialize(content: nil, tool_calls: nil)
      super(role: "assistant", content: content)
      @tool_calls = tool_calls
    end
    
    def to_hash
      hash = { role: @role }
      hash[:content] = @content if @content
      hash[:tool_calls] = @tool_calls if @tool_calls
      hash
    end
  end
  
  class SystemMessage < Message
    def initialize(content:)
      super(role: "system", content: content)
    end
  end
  
  class ToolMessage < Message
    attr_reader :tool_call_id
    
    def initialize(content:, tool_call_id:)
      super(role: "tool", content: content)
      @tool_call_id = tool_call_id
    end
    
    def to_hash
      {
        role: @role,
        content: @content,
        tool_call_id: @tool_call_id
      }
    end
  end
end