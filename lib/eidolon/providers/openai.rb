require 'net/http'
require 'json'
require 'uri'

module Eidolon
  module Providers
    class OpenAI
      API_BASE_URL = "https://api.openai.com/v1"
      
      attr_reader :api_key, :model, :organization
      
      def initialize(api_key:, model: "gpt-4o", organization: nil)
        @api_key = api_key
        @model = model
        @organization = organization
      end
      
      def chat_completion(messages:, tools: nil, tool_choice: nil, response_format: nil)
        uri = URI("#{API_BASE_URL}/chat/completions")
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        
        request = Net::HTTP::Post.new(uri)
        request['Authorization'] = "Bearer #{@api_key}"
        request['Content-Type'] = 'application/json'
        request['OpenAI-Organization'] = @organization if @organization
        
        payload = {
          model: @model,
          messages: messages.map { |msg| msg.respond_to?(:to_hash) ? msg.to_hash(provider_type: :openai) : msg.to_hash }
        }
        
        if tools && !tools.empty?
          payload[:tools] = tools.map(&:to_function_definition)
          payload[:tool_choice] = tool_choice || "auto"
        end
        
        if response_format
          payload[:response_format] = response_format
        end
        
        request.body = JSON.generate(payload)
        
        response = http.request(request)
        
        unless response.code == '200'
          raise Error, "OpenAI API error: #{response.code} - #{response.body}"
        end
        
        JSON.parse(response.body)
      end
    end
  end
end