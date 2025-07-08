require 'eidolon'

# Simple example showing how to chat with images
class VisionAgent < Eidolon::Agent
  def provider
    Eidolon::Providers::OpenAI.new(
      api_key: ENV['OPENAI_API_KEY'],
      model: 'gpt-4o'
    )
  end

  def instructions
    "You are a helpful assistant that can see and analyze images. Describe what you see and answer questions about images."
  end
end

# Initialize the agent
agent = VisionAgent.new

# Example 1: Analyze an image from a file
puts "=== Example 1: Analyze image from file ==="
# Uncomment and modify path to test:
# image = Eidolon::Image.from_file('path/to/your/image.jpg')
# message = Eidolon::UserMessage.new(content: "What's in this image?")
#   .add_attachment(image)
# puts agent.chat(message)

# Example 2: Analyze an image from URL
puts "\n=== Example 2: Analyze image from URL ==="
# Uncomment to test with a real URL:
# image = Eidolon::Image.from_url('https://example.com/image.jpg')
# message = Eidolon::UserMessage.new(content: "Describe this image")
#   .add_attachment(image)
# puts agent.chat(message)

# Example 3: Ask specific questions about an image
puts "\n=== Example 3: Ask specific questions ==="
# Uncomment and modify path to test:
# image = Eidolon::Image.from_file('path/to/your/image.jpg')
# message = Eidolon::UserMessage.new(content: "How many people are in this image?")
#   .add_attachment(image)
# puts agent.chat(message)

# Example 4: Multiple images comparison
puts "\n=== Example 4: Compare multiple images ==="
# Uncomment and modify paths to test:
# image1 = Eidolon::Image.from_file('path/to/first/image.jpg')
# image2 = Eidolon::Image.from_file('path/to/second/image.jpg')
# message = Eidolon::UserMessage.new(content: "What are the main differences between these images?")
#   .add_attachment(image1)
#   .add_attachment(image2)
# puts agent.chat(message)

puts "Simple image chat examples loaded!"
puts "Uncomment the examples and add real image paths to test the functionality."
puts ""
puts "Supported image formats:"
puts "- JPEG (.jpg, .jpeg)"
puts "- PNG (.png)"
puts "- GIF (.gif)"
puts "- WebP (.webp)"
puts ""
puts "You can load images from:"
puts "- Local files: Eidolon::Image.from_file('path/to/image.jpg')"
puts "- URLs: Eidolon::Image.from_url('https://example.com/image.jpg')"
puts "- Base64 data: Eidolon::Image.new(content: base64_data, content_type: :base64)"