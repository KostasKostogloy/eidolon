require 'base64'
require 'net/http'
require 'uri'

module Eidolon
  module AttachmentContentType
    URL = "url"
    BASE64 = "base64"
  end

  class Attachment
    attr_reader :content, :content_type, :media_type, :filename
    
    def initialize(content:, content_type:, media_type:, filename: nil)
      @content = content
      @content_type = content_type
      @media_type = media_type
      @filename = filename
    end
    
    def to_hash
      {
        type: @media_type.split('/').first,
        source: build_source_hash
      }
    end
    
    private
    
    def build_source_hash
      case @content_type
      when AttachmentContentType::URL
        {
          type: "url",
          url: @content
        }
      when AttachmentContentType::BASE64
        {
          type: "base64",
          media_type: @media_type,
          data: @content
        }
      else
        raise ArgumentError, "Unknown content type: #{@content_type}"
      end
    end
  end
  
  class Image < Attachment
    def initialize(content:, content_type: AttachmentContentType::BASE64, media_type: "image/jpeg", filename: nil)
      super(content: content, content_type: content_type, media_type: media_type, filename: filename)
    end
    
    def self.from_file(file_path, media_type: nil)
      unless File.exist?(file_path)
        raise ArgumentError, "File not found: #{file_path}"
      end
      
      # Auto-detect media type if not provided
      if media_type.nil?
        extension = File.extname(file_path).downcase
        media_type = case extension
                    when '.jpg', '.jpeg' then 'image/jpeg'
                    when '.png' then 'image/png'
                    when '.gif' then 'image/gif'
                    when '.webp' then 'image/webp'
                    else 'image/jpeg'
                    end
      end
      
      content = Base64.strict_encode64(File.read(file_path))
      filename = File.basename(file_path)
      
      new(
        content: content,
        content_type: AttachmentContentType::BASE64,
        media_type: media_type,
        filename: filename
      )
    end
    
    def self.from_url(url, media_type: "image/jpeg")
      new(
        content: url,
        content_type: AttachmentContentType::URL,
        media_type: media_type
      )
    end
    
    def to_openai_format
      case @content_type
      when AttachmentContentType::URL
        {
          type: "image_url",
          image_url: {
            url: @content
          }
        }
      when AttachmentContentType::BASE64
        {
          type: "image_url",
          image_url: {
            url: "data:#{@media_type};base64,#{@content}"
          }
        }
      end
    end
    
    def to_anthropic_format
      case @content_type
      when AttachmentContentType::URL
        # Anthropic doesn't support URL images directly, need to download and encode
        download_and_encode_for_anthropic
      when AttachmentContentType::BASE64
        {
          type: "image",
          source: {
            type: "base64",
            media_type: @media_type,
            data: @content
          }
        }
      end
    end
    
    def to_gemini_format
      case @content_type
      when AttachmentContentType::URL
        {
          inline_data: {
            mime_type: @media_type,
            data: download_and_encode_url
          }
        }
      when AttachmentContentType::BASE64
        {
          inline_data: {
            mime_type: @media_type,
            data: @content
          }
        }
      end
    end
    
    private
    
    def download_and_encode_for_anthropic
      encoded_data = download_and_encode_url
      {
        type: "image",
        source: {
          type: "base64",
          media_type: @media_type,
          data: encoded_data
        }
      }
    end
    
    def download_and_encode_url
      uri = URI(@content)
      response = Net::HTTP.get_response(uri)
      
      if response.code == '200'
        Base64.strict_encode64(response.body)
      else
        raise Error, "Failed to download image from URL: #{@content}"
      end
    end
  end
  
  class Document < Attachment
    def initialize(content:, content_type: AttachmentContentType::BASE64, media_type: "application/pdf", filename: nil)
      super(content: content, content_type: content_type, media_type: media_type, filename: filename)
    end
    
    def self.from_file(file_path, media_type: nil)
      unless File.exist?(file_path)
        raise ArgumentError, "File not found: #{file_path}"
      end
      
      # Auto-detect media type if not provided
      if media_type.nil?
        extension = File.extname(file_path).downcase
        media_type = case extension
                    when '.pdf' then 'application/pdf'
                    when '.txt' then 'text/plain'
                    when '.md' then 'text/markdown'
                    when '.doc' then 'application/msword'
                    when '.docx' then 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                    else 'application/octet-stream'
                    end
      end
      
      content = Base64.strict_encode64(File.read(file_path))
      filename = File.basename(file_path)
      
      new(
        content: content,
        content_type: AttachmentContentType::BASE64,
        media_type: media_type,
        filename: filename
      )
    end
    
    def self.from_url(url, media_type: "application/pdf")
      new(
        content: url,
        content_type: AttachmentContentType::URL,
        media_type: media_type
      )
    end
    
    # Note: Document support varies by provider
    # Most providers have limited document support compared to images
    def to_provider_format(provider_type)
      case provider_type
      when :openai
        # OpenAI has limited document support
        raise NotImplementedError, "Document attachments not fully supported by OpenAI"
      when :anthropic
        # Anthropic has some document support via Claude
        to_anthropic_format
      when :gemini
        # Gemini has document support
        to_gemini_format
      else
        to_hash
      end
    end
    
    def to_anthropic_format
      case @content_type
      when AttachmentContentType::BASE64
        {
          type: "document",
          source: {
            type: "base64",
            media_type: @media_type,
            data: @content
          }
        }
      else
        raise NotImplementedError, "URL documents not supported for Anthropic"
      end
    end
    
    def to_gemini_format
      case @content_type
      when AttachmentContentType::BASE64
        {
          inline_data: {
            mime_type: @media_type,
            data: @content
          }
        }
      else
        raise NotImplementedError, "URL documents not supported for Gemini"
      end
    end
  end
end