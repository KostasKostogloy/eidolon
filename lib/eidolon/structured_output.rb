module Eidolon
  module StructuredOutput
    class SchemaProperty
      attr_reader :description, :required, :type, :enum_values, :format
      
      def initialize(description:, required: false, type: nil, enum_values: nil, format: nil)
        @description = description
        @required = required
        @type = type
        @enum_values = enum_values
        @format = format
      end
    end
    
    class Schema
      attr_reader :properties, :required_fields, :title
      
      def initialize(title: nil)
        @properties = {}
        @required_fields = []
        @title = title
      end
      
      def add_property(name, schema_property)
        @properties[name] = schema_property
        @required_fields << name if schema_property.required
      end
      
      def to_json_schema
        schema = {
          type: "object",
          properties: {},
          required: @required_fields,
          additionalProperties: false
        }
        
        schema[:title] = @title if @title
        
        @properties.each do |name, prop|
          property_schema = {
            type: prop.type || "string",
            description: prop.description
          }
          
          property_schema[:enum] = prop.enum_values if prop.enum_values
          property_schema[:format] = prop.format if prop.format
          
          schema[:properties][name] = property_schema
        end
        
        schema
      end
    end
    
    module ClassMethods
      def structured_output_schema(title: nil)
        @schema = Schema.new(title: title || self.name)
        yield @schema if block_given?
        @schema
      end
      
      def schema_property(name, description:, required: false, type: "string", enum_values: nil, format: nil)
        @schema ||= Schema.new(title: self.name)
        property = SchemaProperty.new(
          description: description,
          required: required,
          type: type,
          enum_values: enum_values,
          format: format
        )
        @schema.add_property(name, property)
        
        # Define getter and setter methods
        attr_accessor name
      end
      
      def get_schema
        @schema || Schema.new(title: self.name)
      end
      
      def from_hash(hash)
        instance = self.new
        hash.each do |key, value|
          setter_method = "#{key}="
          if instance.respond_to?(setter_method)
            instance.send(setter_method, value)
          end
        end
        instance
      end
    end
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    def to_hash
      hash = {}
      self.class.get_schema.properties.each_key do |property_name|
        value = self.send(property_name)
        hash[property_name] = value unless value.nil?
      end
      hash
    end
    
    def validate
      errors = []
      schema = self.class.get_schema
      
      schema.required_fields.each do |field|
        value = self.send(field)
        if value.nil? || (value.respond_to?(:empty?) && value.empty?)
          errors << "#{field} is required"
        end
      end
      
      schema.properties.each do |name, prop|
        value = self.send(name)
        next if value.nil?
        
        if prop.enum_values && !prop.enum_values.include?(value)
          errors << "#{name} must be one of: #{prop.enum_values.join(', ')}"
        end
        
        case prop.type
        when "integer"
          unless value.is_a?(Integer)
            errors << "#{name} must be an integer"
          end
        when "number"
          unless value.is_a?(Numeric)
            errors << "#{name} must be a number"
          end
        when "boolean"
          unless [true, false].include?(value)
            errors << "#{name} must be a boolean"
          end
        when "array"
          unless value.is_a?(Array)
            errors << "#{name} must be an array"
          end
        end
      end
      
      errors
    end
    
    def valid?
      validate.empty?
    end
  end
end