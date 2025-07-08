require 'net/http'
require 'json'
require 'uri'

module Eidolon
  module Providers
    class Anthropic
      API_BASE_URL = "https://api.anthropic.com/v1"
      
      attr_reader :api_key, :model, :max_tokens
      
      def initialize(api_key:, model: "claude-3-5-sonnet-20241022", max_tokens: 4096)
        @api_key = api_key
        @model = model
        @max_tokens = max_tokens
      end
      
      def chat_completion(messages:, tools: nil, tool_choice: nil, response_format: nil)
        uri = URI("#{API_BASE_URL}/messages")
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        
        request = Net::HTTP::Post.new(uri)
        request['x-api-key'] = @api_key
        request['Content-Type'] = 'application/json'
        request['anthropic-version'] = '2023-06-01'
        
        # Convert messages to Anthropic format
        anthropic_messages = convert_messages_to_anthropic(messages)
        
        payload = {
          model: @model,
          max_tokens: @max_tokens,
          messages: anthropic_messages[:messages]
        }
        
        payload[:system] = anthropic_messages[:system] if anthropic_messages[:system]
        
        if tools && !tools.empty?
          payload[:tools] = tools.map(&:to_anthropic_tool_definition)
          payload[:tool_choice] = convert_tool_choice(tool_choice)
        end
        
        # For structured output, we'll add instructions to the system message
        if response_format
          structured_instruction = build_structured_output_instruction(response_format)
          if payload[:system]
            payload[:system] = "#{payload[:system]}\n\n#{structured_instruction}"
          else
            payload[:system] = structured_instruction
          end
        end
        
        request.body = JSON.generate(payload)
        
        response = http.request(request)
        
        unless response.code == '200'
          raise Error, "Anthropic API error: #{response.code} - #{response.body}"
        end
        
        anthropic_response = JSON.parse(response.body)
        convert_anthropic_response_to_openai_format(anthropic_response)
      end
      
      private
      
      def convert_messages_to_anthropic(messages)
        system_message = nil
        anthropic_messages = []
        
        messages.each do |message|
          case message.role
          when "system"
            system_message = message.content
          when "user"
            if message.respond_to?(:has_attachments?) && message.has_attachments?
              # Use the message's own Anthropic format conversion
              anthropic_messages << message.to_hash(provider_type: :anthropic)
            else
              anthropic_messages << { role: "user", content: message.content }
            end
          when "assistant"
            content = []
            content << { type: "text", text: message.content } if message.content
            
            if message.respond_to?(:tool_calls) && message.tool_calls
              message.tool_calls.each do |tool_call|
                content << {
                  type: "tool_use",
                  id: tool_call["id"],
                  name: tool_call["function"]["name"],
                  input: JSON.parse(tool_call["function"]["arguments"])
                }
              end
            end
            
            anthropic_messages << { role: "assistant", content: content }
          when "tool"
            anthropic_messages << {
              role: "user",
              content: [
                {
                  type: "tool_result",
                  tool_use_id: message.tool_call_id,
                  content: message.content
                }
              ]
            }
          end
        end
        
        { messages: anthropic_messages, system: system_message }
      end
      
      def convert_tool_choice(tool_choice)
        case tool_choice
        when "auto", nil
          { type: "auto" }
        when "none"
          { type: "none" }
        else
          { type: "tool", name: tool_choice }
        end
      end
      
      def convert_anthropic_response_to_openai_format(anthropic_response)
        content = nil
        tool_calls = nil
        
        anthropic_response["content"].each do |block|
          case block["type"]
          when "text"
            content = block["text"]
          when "tool_use"
            tool_calls ||= []
            tool_calls << {
              "id" => block["id"],
              "type" => "function",
              "function" => {
                "name" => block["name"],
                "arguments" => JSON.generate(block["input"])
              }
            }
          end
        end
        
        {
          "choices" => [
            {
              "message" => {
                "content" => content,
                "tool_calls" => tool_calls
              }
            }
          ]
        }
      end
      
      def build_structured_output_instruction(response_format)
        if response_format[:type] == "json_schema"
          schema = response_format[:json_schema][:schema]
          "You must respond with valid JSON that matches this exact schema: #{JSON.generate(schema)}. Do not include any text outside of the JSON response."
        else
          "You must respond in the specified format."
        end
      end
    end
  end
end