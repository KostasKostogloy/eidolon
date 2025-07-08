module Eidolon
  class Agent
    attr_reader :conversation_history
    
    def initialize
      @conversation_history = []
      setup_system_message
    end
    
    def provider
      raise NotImplementedError, "Agent subclasses must implement the provider method"
    end
    
    def instructions
      nil
    end
    
    def tools
      []
    end
    
    def chat(message)
      user_message = UserMessage.new(content: message)
      @conversation_history << user_message
      
      loop do
        response = provider.chat_completion(
          messages: @conversation_history,
          tools: tools
        )
        
        choice = response["choices"][0]
        message = choice["message"]
        
        assistant_message = AssistantMessage.new(
          content: message["content"],
          tool_calls: message["tool_calls"]
        )
        
        @conversation_history << assistant_message
        
        if message["tool_calls"]
          process_tool_calls(message["tool_calls"])
        else
          return assistant_message.content
        end
      end
    end
    
    def structured(message, output_class, max_retries: 3)
      user_message = UserMessage.new(content: message)
      @conversation_history << user_message
      
      schema = output_class.get_schema
      response_format = {
        type: "json_schema",
        json_schema: {
          name: schema.title || output_class.name,
          schema: schema.to_json_schema,
          strict: true
        }
      }
      
      retries = 0
      
      loop do
        begin
          response = provider.chat_completion(
            messages: @conversation_history,
            tools: tools,
            response_format: response_format
          )
          
          choice = response["choices"][0]
          message_content = choice["message"]["content"]
          
          assistant_message = AssistantMessage.new(content: message_content)
          @conversation_history << assistant_message
          
          # Parse and validate the JSON response
          begin
            parsed_data = JSON.parse(message_content)
            result = output_class.from_hash(parsed_data)
            
            # Validate the result
            validation_errors = result.validate
            if validation_errors.empty?
              return result
            else
              raise StructuredOutputError, "Validation failed: #{validation_errors.join(', ')}"
            end
          rescue JSON::ParserError => e
            raise StructuredOutputError, "Invalid JSON response: #{e.message}"
          end
          
        rescue StructuredOutputError => e
          retries += 1
          if retries >= max_retries
            raise e
          end
          
          # Add error message to conversation and retry
          error_message = UserMessage.new(
            content: "The response was invalid: #{e.message}. Please provide a valid JSON response that matches the required schema."
          )
          @conversation_history << error_message
        end
      end
    end
    
    private
    
    def setup_system_message
      return unless instructions
      
      system_content = case instructions
                      when SystemPrompt
                        instructions.to_s
                      when String
                        instructions
                      else
                        instructions.to_s
                      end
      
      @conversation_history << SystemMessage.new(content: system_content)
    end
    
    def process_tool_calls(tool_calls)
      tool_calls.each do |tool_call|
        tool_name = tool_call["function"]["name"]
        tool_args = JSON.parse(tool_call["function"]["arguments"])
        
        tool = find_tool(tool_name)
        if tool
          begin
            result = tool.call(**tool_args.transform_keys(&:to_sym))
            tool_message = ToolMessage.new(
              content: result.to_s,
              tool_call_id: tool_call["id"]
            )
            @conversation_history << tool_message
          rescue => e
            error_message = ToolMessage.new(
              content: "Error executing tool: #{e.message}",
              tool_call_id: tool_call["id"]
            )
            @conversation_history << error_message
          end
        else
          error_message = ToolMessage.new(
            content: "Tool '#{tool_name}' not found",
            tool_call_id: tool_call["id"]
          )
          @conversation_history << error_message
        end
      end
    end
    
    def find_tool(name)
      tools.find { |tool| tool.name == name }
    end
  end
end