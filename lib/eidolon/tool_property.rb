module Eidolon
  class ToolProperty
    attr_reader :name, :type, :description, :required, :enum_values
    
    def initialize(name:, type:, description:, required: false, enum_values: nil)
      @name = name
      @type = type
      @description = description
      @required = required
      @enum_values = enum_values
    end
    
    def to_schema
      schema = {
        type: type_to_json_schema(@type),
        description: @description
      }
      
      schema[:enum] = @enum_values if @enum_values
      schema
    end
    
    private
    
    def type_to_json_schema(type)
      case type
      when :string then "string"
      when :integer then "integer"
      when :number then "number"
      when :boolean then "boolean"
      when :array then "array"
      when :object then "object"
      else "string"
      end
    end
  end
end