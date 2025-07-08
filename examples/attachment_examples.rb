require 'eidolon'

# Example: Image Analysis Agent
class ImageAnalysisAgent < Eidolon::Agent
  def provider
    Eidolon::Providers::OpenAI.new(
      api_key: ENV['OPENAI_API_KEY'],
      model: 'gpt-4o'
    )
  end

  def instructions
    "You are an image analysis expert. Analyze images and provide detailed descriptions, identify objects, text, and answer questions about the image content."
  end
end

# Example: Document Processing Agent  
class DocumentAgent < Eidolon::Agent
  def provider
    # Anthropic has better document support
    Eidolon::Providers::Anthropic.new(
      api_key: ENV['ANTHROPIC_API_KEY'],
      model: 'claude-3-5-sonnet-20241022'
    )
  end

  def instructions
    "You are a document analysis expert. Read and analyze documents, extract key information, summarize content, and answer questions about the document."
  end
end

# Example usage with different attachment types:

# 1. Image from file
def analyze_image_from_file
  agent = ImageAnalysisAgent.new
  
  # Create image attachment from local file
  image = Eidolon::Image.from_file('/path/to/image.jpg')
  
  # Create message with attachment
  message = Eidolon::UserMessage.new(content: "What do you see in this image?")
  message.add_attachment(image)
  
  response = agent.chat(message)
  puts "Image analysis: #{response}"
end

# 2. Image from URL
def analyze_image_from_url
  agent = ImageAnalysisAgent.new
  
  # Create image attachment from URL
  image = Eidolon::Image.from_url('https://example.com/image.jpg')
  
  # Create message with attachment
  message = Eidolon::UserMessage.new(content: "Describe this image in detail")
  message.add_attachment(image)
  
  response = agent.chat(message)
  puts "Image description: #{response}"
end

# 3. Multiple images
def compare_multiple_images
  agent = ImageAnalysisAgent.new
  
  # Create multiple image attachments
  image1 = Eidolon::Image.from_file('/path/to/before.jpg')
  image2 = Eidolon::Image.from_file('/path/to/after.jpg')
  
  # Create message with multiple attachments
  message = Eidolon::UserMessage.new(content: "Compare these two images and describe the differences")
  message.add_attachment(image1).add_attachment(image2)
  
  response = agent.chat(message)
  puts "Comparison: #{response}"
end

# 4. Document analysis
def analyze_document
  agent = DocumentAgent.new
  
  # Create document attachment
  document = Eidolon::Document.from_file('/path/to/document.pdf')
  
  # Create message with document attachment
  message = Eidolon::UserMessage.new(content: "Summarize the key points from this document")
  message.add_attachment(document)
  
  response = agent.chat(message)
  puts "Document summary: #{response}"
end

# 5. Working with different image formats
def process_different_image_formats
  agent = ImageAnalysisAgent.new
  
  # PNG image
  png_image = Eidolon::Image.from_file('/path/to/screenshot.png', media_type: 'image/png')
  
  # JPEG image  
  jpg_image = Eidolon::Image.from_file('/path/to/photo.jpg', media_type: 'image/jpeg')
  
  # WebP image
  webp_image = Eidolon::Image.from_file('/path/to/modern.webp', media_type: 'image/webp')
  
  [png_image, jpg_image, webp_image].each_with_index do |image, index|
    message = Eidolon::UserMessage.new(content: "What format is this image and what does it show?")
    message.add_attachment(image)
    
    response = agent.chat(message)
    puts "Image #{index + 1} analysis: #{response}"
  end
end

# 6. Base64 encoded image
def analyze_base64_image
  agent = ImageAnalysisAgent.new
  
  # Read and encode image manually
  image_data = File.read('/path/to/image.jpg')
  base64_data = Base64.strict_encode64(image_data)
  
  # Create image attachment with base64 data
  image = Eidolon::Image.new(
    content: base64_data,
    content_type: Eidolon::AttachmentContentType::BASE64,
    media_type: 'image/jpeg'
  )
  
  message = Eidolon::UserMessage.new(content: "Analyze this base64 encoded image")
  message.add_attachment(image)
  
  response = agent.chat(message)
  puts "Base64 image analysis: #{response}"
end

# 7. OCR and text extraction
def extract_text_from_image
  agent = ImageAnalysisAgent.new
  
  image = Eidolon::Image.from_file('/path/to/text_image.jpg')
  
  message = Eidolon::UserMessage.new(content: "Extract all text from this image and format it clearly")
  message.add_attachment(image)
  
  response = agent.chat(message)
  puts "Extracted text: #{response}"
end

# 8. Structured output with images
class ImageAnalysis
  include Eidolon::StructuredOutput
  
  schema_property :objects_detected, description: "List of objects detected in the image", type: "array"
  schema_property :text_content, description: "Any text found in the image", type: "string"
  schema_property :dominant_colors, description: "Main colors in the image", type: "array"
  schema_property :scene_description, description: "Overall description of the scene", type: "string"
  schema_property :confidence_score, description: "Confidence in the analysis (1-10)", type: "integer"
end

def structured_image_analysis
  agent = ImageAnalysisAgent.new
  
  image = Eidolon::Image.from_file('/path/to/complex_image.jpg')
  
  message = Eidolon::UserMessage.new(content: "Provide a detailed analysis of this image")
  message.add_attachment(image)
  
  # Note: structured() method would need to be enhanced to support attachments
  # This is conceptual - would require additional implementation
  analysis = agent.structured(message, ImageAnalysis)
  
  puts "Objects: #{analysis.objects_detected.join(', ')}"
  puts "Text: #{analysis.text_content}"
  puts "Colors: #{analysis.dominant_colors.join(', ')}"
  puts "Scene: #{analysis.scene_description}"
  puts "Confidence: #{analysis.confidence_score}/10"
end

# Usage examples (commented out since they require actual files):
# analyze_image_from_file
# analyze_image_from_url  
# compare_multiple_images
# analyze_document
# process_different_image_formats
# extract_text_from_image

puts "Attachment examples loaded!"
puts "Uncomment the method calls at the bottom to test with actual files."