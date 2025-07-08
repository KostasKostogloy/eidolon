require 'net/http'
require 'json'
require 'uri'

module Eidolon
  module Providers
    class OpenRouter
      API_BASE_URL = "https://openrouter.ai/api/v1"
      
      attr_reader :api_key, :model, :site_url, :site_name
      
      def initialize(api_key:, model: "openai/gpt-4o", site_url: nil, site_name: nil)
        @api_key = api_key
        @model = model
        @site_url = site_url
        @site_name = site_name
      end
      
      def chat_completion(messages:, tools: nil, tool_choice: nil, response_format: nil)
        uri = URI("#{API_BASE_URL}/chat/completions")
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        
        request = Net::HTTP::Post.new(uri)
        request['Authorization'] = "Bearer #{@api_key}"
        request['Content-Type'] = 'application/json'
        request['HTTP-Referer'] = @site_url if @site_url
        request['X-Title'] = @site_name if @site_name
        
        payload = {
          model: @model,
          messages: messages.map { |msg| msg.respond_to?(:to_hash) ? msg.to_hash(provider_type: :openrouter) : msg.to_hash }
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
          raise Error, "OpenRouter API error: #{response.code} - #{response.body}"
        end
        
        JSON.parse(response.body)
      end
    end
  end
end