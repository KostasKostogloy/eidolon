module Eidolon
  class Tool
    attr_reader :name, :description
    
    def initialize(name:, description:)
      @name = name
      @description = description
    end
    
    def properties
      []
    end
    
    def call(**args)
      raise NotImplementedError, "Tool subclasses must implement the call method"
    end
    
    def to_function_definition
      {
        type: "function",
        function: {
          name: @name,
          description: @description,
          parameters: build_parameters_schema
        }
      }
    end
    
    def to_anthropic_tool_definition
      {
        name: @name,
        description: @description,
        input_schema: build_parameters_schema
      }
    end
    
    def to_gemini_tool_definition
      {
        name: @name,
        description: @description,
        parameters: build_parameters_schema
      }
    end
    
    private
    
    def build_parameters_schema
      props = properties
      
      schema = {
        type: "object",
        properties: {},
        required: []
      }
      
      props.each do |prop|
        schema[:properties][prop.name] = prop.to_schema
        schema[:required] << prop.name if prop.required
      end
      
      schema
    end
  end
end