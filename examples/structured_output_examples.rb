require 'eidolon'

# Example 1: Person Information Extraction
class Person
  include Eidolon::StructuredOutput
  
  schema_property :name, description: "The person's full name", required: true, type: "string"
  schema_property :age, description: "The person's age", required: false, type: "integer"
  schema_property :occupation, description: "The person's job or profession", required: false, type: "string"
  schema_property :hobbies, description: "List of hobbies", required: false, type: "array"
end

# Example 2: Product Review Analysis
class ProductReview
  include Eidolon::StructuredOutput
  
  schema_property :sentiment, 
    description: "Overall sentiment of the review", 
    required: true, 
    type: "string", 
    enum_values: ["positive", "negative", "neutral"]
  
  schema_property :rating, 
    description: "Numeric rating out of 5", 
    required: true, 
    type: "integer"
  
  schema_property :pros, 
    description: "List of positive aspects mentioned", 
    required: false, 
    type: "array"
  
  schema_property :cons, 
    description: "List of negative aspects mentioned", 
    required: false, 
    type: "array"
  
  schema_property :summary, 
    description: "Brief summary of the review", 
    required: true, 
    type: "string"
end

# Example 3: Meeting Summary
class MeetingNotes
  include Eidolon::StructuredOutput
  
  structured_output_schema(title: "Meeting Summary") do |schema|
    schema.add_property(:meeting_title, 
      Eidolon::StructuredOutput::SchemaProperty.new(
        description: "Title or subject of the meeting",
        required: true,
        type: "string"
      ))
    
    schema.add_property(:attendees,
      Eidolon::StructuredOutput::SchemaProperty.new(
        description: "List of meeting attendees",
        required: true,
        type: "array"
      ))
    
    schema.add_property(:action_items,
      Eidolon::StructuredOutput::SchemaProperty.new(
        description: "List of action items and tasks",
        required: false,
        type: "array"
      ))
    
    schema.add_property(:next_meeting_date,
      Eidolon::StructuredOutput::SchemaProperty.new(
        description: "Date of next meeting if mentioned",
        required: false,
        type: "string",
        format: "date"
      ))
  end
  
  attr_accessor :meeting_title, :attendees, :action_items, :next_meeting_date
end

# Agent for structured output
class DataExtractionAgent < Eidolon::Agent
  def provider
    Eidolon::Providers::OpenAI.new(
      api_key: ENV['OPENAI_API_KEY'],
      model: 'gpt-4o'
    )
  end

  def instructions
    "You are a data extraction specialist. Extract structured information from the provided text accurately."
  end
end

# Usage examples:
# 
# agent = DataExtractionAgent.new
# 
# # Example 1: Extract person information
# text = "Hi, I'm John Smith, a 35-year-old software engineer. I love hiking and playing guitar."
# person = agent.structured(text, Person)
# puts "Name: #{person.name}"
# puts "Age: #{person.age}"
# puts "Occupation: #{person.occupation}"
# puts "Hobbies: #{person.hobbies.join(', ')}"
# 
# # Example 2: Analyze product review
# review_text = "This phone is amazing! Great camera quality and battery life. However, it's a bit expensive and the screen could be bigger. Overall rating: 4/5"
# review = agent.structured(review_text, ProductReview)
# puts "Sentiment: #{review.sentiment}"
# puts "Rating: #{review.rating}/5"
# puts "Pros: #{review.pros.join(', ')}"
# puts "Cons: #{review.cons.join(', ')}"
# puts "Summary: #{review.summary}"
# 
# # Example 3: Extract meeting notes
# meeting_text = "Team standup meeting with Alice, Bob, and Carol. Discussed project progress. Action items: Alice to finish API documentation by Friday, Bob to review pull requests. Next meeting scheduled for Monday."
# notes = agent.structured(meeting_text, MeetingNotes)
# puts "Meeting: #{notes.meeting_title}"
# puts "Attendees: #{notes.attendees.join(', ')}"
# puts "Action Items: #{notes.action_items.join('; ')}"
# puts "Next Meeting: #{notes.next_meeting_date}"

# Example 4: Error handling and validation
class StrictContact
  include Eidolon::StructuredOutput
  
  schema_property :email, 
    description: "Valid email address", 
    required: true, 
    type: "string", 
    format: "email"
  
  schema_property :phone, 
    description: "Phone number", 
    required: true, 
    type: "string"
  
  schema_property :country, 
    description: "Country code", 
    required: true, 
    type: "string", 
    enum_values: ["US", "CA", "UK", "AU", "DE", "FR"]
end

# Example with retry mechanism
# begin
#   contact = agent.structured("My email is john@example.com, phone is 555-1234, I'm in the US", StrictContact, max_retries: 2)
#   puts "Contact extracted successfully!"
# rescue Eidolon::StructuredOutputError => e
#   puts "Failed to extract valid contact: #{e.message}"
# end