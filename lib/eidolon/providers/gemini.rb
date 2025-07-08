require 'net/http'
require 'json'
require 'uri'
require 'securerandom'

module Eidolon
  module Providers
    class Gemini
      API_BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
      
      attr_reader :api_key, :model
      
      def initialize(api_key:, model: "gemini-1.5-pro-002")
        @api_key = api_key
        @model = model
      end
      
      def chat_completion(messages:, tools: nil, tool_choice: nil, response_format: nil)
        uri = URI("#{API_BASE_URL}/models/#{@model}:generateContent?key=#{@api_key}")
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        
        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = 'application/json'
        
        # Convert messages to Gemini format
        gemini_request = convert_messages_to_gemini(messages)
        
        if tools && !tools.empty?
          gemini_request[:tools] = [{ function_declarations: tools.map(&:to_gemini_tool_definition) }]
          gemini_request[:tool_config] = convert_tool_choice(tool_choice)
        end
        
        # For structured output, we'll add generation config
        if response_format
          gemini_request[:generation_config] = build_generation_config(response_format)
        end
        
        request.body = JSON.generate(gemini_request)
        
        response = http.request(request)
        
        unless response.code == '200'
          raise Error, "Gemini API error: #{response.code} - #{response.body}"
        end
        
        gemini_response = JSON.parse(response.body)
        convert_gemini_response_to_openai_format(gemini_response)
      end
      
      private
      
      def convert_messages_to_gemini(messages)
        system_instruction = nil
        contents = []
        
        messages.each do |message|
          case message.role
          when "system"
            system_instruction = { parts: [{ text: message.content }] }
          when "user"
            if message.respond_to?(:has_attachments?) && message.has_attachments?
              # Use the message's own Gemini format conversion
              contents << message.to_hash(provider_type: :gemini)
            else
              contents << { role: "user", parts: [{ text: message.content }] }
            end
          when "assistant"
            parts = []
            parts << { text: message.content } if message.content
            
            if message.respond_to?(:tool_calls) && message.tool_calls
              message.tool_calls.each do |tool_call|
                parts << {
                  function_call: {
                    name: tool_call["function"]["name"],
                    args: JSON.parse(tool_call["function"]["arguments"])
                  }
                }
              end
            end
            
            contents << { role: "model", parts: parts }
          when "tool"
            contents << {
              role: "function",
              parts: [
                {
                  function_response: {
                    name: extract_function_name_from_history(message.tool_call_id),
                    response: { result: message.content }
                  }
                }
              ]
            }
          end
        end
        
        request = { contents: contents }
        request[:system_instruction] = system_instruction if system_instruction
        request
      end
      
      def extract_function_name_from_history(tool_call_id)
        "unknown_function"
      end
      
      def convert_tool_choice(tool_choice)
        case tool_choice
        when "auto", nil
          { function_calling_config: { mode: "AUTO" } }
        when "none"
          { function_calling_config: { mode: "NONE" } }
        else
          { function_calling_config: { mode: "ANY", allowed_function_names: [tool_choice] } }
        end
      end
      
      def convert_gemini_response_to_openai_format(gemini_response)
        return { "choices" => [{ "message" => { "content" => "No response generated" } }] } unless gemini_response["candidates"]
        
        candidate = gemini_response["candidates"][0]
        content = nil
        tool_calls = nil
        
        candidate["content"]["parts"].each do |part|
          if part["text"]
            content = part["text"]
          elsif part["function_call"]
            tool_calls ||= []
            tool_calls << {
              "id" => generate_tool_call_id,
              "type" => "function",
              "function" => {
                "name" => part["function_call"]["name"],
                "arguments" => JSON.generate(part["function_call"]["args"])
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
      
      def generate_tool_call_id
        "call_#{SecureRandom.hex(12)}"
      end
      
      def build_generation_config(response_format)
        if response_format[:type] == "json_schema"
          {
            response_mime_type: "application/json",
            response_schema: response_format[:json_schema][:schema]
          }
        else
          {}
        end
      end
    end
  end
end