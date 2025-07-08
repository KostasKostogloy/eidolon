# Eidolon

A Ruby gem for creating LLM agents with tool support, inspired by the Neuron AI framework. Eidolon provides a simple and elegant way to build conversational AI agents with support for multiple LLM providers including OpenAI, Anthropic, Google Gemini, and OpenRouter.

## Features

- **Easy Agent Creation**: Simple class-based approach for defining agents
- **Multiple LLM Providers**: Built-in support for OpenAI, Anthropic, Google Gemini, and OpenRouter
- **Tool System**: Comprehensive tool calling system for extending agent capabilities
- **Structured Output**: Extract structured data with automatic validation and retry logic
- **Attachments**: Support for images and documents with automatic format conversion
- **Structured Prompts**: SystemPrompt class for organized agent instructions
- **Message Management**: Built-in conversation history and message handling
- **Provider Flexibility**: Easy switching between different LLM providers

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'eidolon'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install eidolon

## Quick Start

### Simple Agent

```ruby
require 'eidolon'

class MyAgent < Eidolon::Agent
  def provider
    Eidolon::Providers::OpenAI.new(
      api_key: ENV['OPENAI_API_KEY'],
      model: 'gpt-4o'
    )
  end

  def instructions
    "You are a helpful assistant."
  end
end

agent = MyAgent.new
response = agent.chat("Hello!")
puts response
```

### Agent with Tools

```ruby
class WeatherTool < Eidolon::Tool
  def initialize
    super(
      name: 'get_weather',
      description: 'Get current weather for a location'
    )
  end

  def properties
    [
      Eidolon::ToolProperty.new(
        name: 'location',
        type: :string,
        description: 'The city and state/country',
        required: true
      )
    ]
  end

  def call(location:)
    "The weather in #{location} is sunny and 72°F"
  end
end

class WeatherAgent < Eidolon::Agent
  def provider
    Eidolon::Providers::OpenAI.new(
      api_key: ENV['OPENAI_API_KEY'],
      model: 'gpt-4o'
    )
  end

  def instructions
    Eidolon::SystemPrompt.new(
      background: "You are a weather assistant.",
      steps: [
        "Ask for the user's location if not provided",
        "Use the get_weather tool to fetch current conditions",
        "Provide a friendly weather report"
      ]
    )
  end

  def tools
    [WeatherTool.new]
  end
end

agent = WeatherAgent.new
response = agent.chat("What's the weather like in San Francisco?")
puts response
```

### Structured Output

Extract structured data from LLM responses with automatic validation:

```ruby
class Person
  include Eidolon::StructuredOutput
  
  schema_property :name, description: "Person's full name", required: true
  schema_property :age, description: "Person's age", type: "integer"
  schema_property :occupation, description: "Person's job"
  schema_property :hobbies, description: "List of hobbies", type: "array"
end

class DataAgent < Eidolon::Agent
  def provider
    Eidolon::Providers::OpenAI.new(
      api_key: ENV['OPENAI_API_KEY'],
      model: 'gpt-4o'
    )
  end

  def instructions
    "Extract person information from the given text."
  end
end

agent = DataAgent.new
text = "Hi, I'm John Smith, a 35-year-old software engineer. I love hiking and playing guitar."
person = agent.structured(text, Person)

puts "Name: #{person.name}"
puts "Age: #{person.age}"
puts "Job: #{person.occupation}"
puts "Hobbies: #{person.hobbies.join(', ')}"
```

### Attachments

Send images and documents to your agents:

```ruby
class VisionAgent < Eidolon::Agent
  def provider
    Eidolon::Providers::OpenAI.new(
      api_key: ENV['OPENAI_API_KEY'],
      model: 'gpt-4o'
    )
  end

  def instructions
    "You can see and analyze images. Describe what you see."
  end
end

agent = VisionAgent.new

# Image from file
image = Eidolon::Image.from_file('path/to/image.jpg')
message = Eidolon::UserMessage.new(content: "What's in this image?")
  .add_attachment(image)

response = agent.chat(message)
puts response

# Image from URL
url_image = Eidolon::Image.from_url('https://example.com/image.jpg')
message = Eidolon::UserMessage.new(content: "Describe this image")
  .add_attachment(url_image)

response = agent.chat(message)
puts response

# Multiple attachments
image1 = Eidolon::Image.from_file('before.jpg')
image2 = Eidolon::Image.from_file('after.jpg')
message = Eidolon::UserMessage.new(content: "Compare these images")
  .add_attachment(image1)
  .add_attachment(image2)

response = agent.chat(message)
puts response
```

## Core Components

### Agent

The base class for all agents. Subclass this and implement:

- `provider`: Returns a provider instance (OpenAI, Anthropic, Gemini, or OpenRouter)
- `instructions`: Returns instructions (String or SystemPrompt)
- `tools`: Returns an array of tools (optional)

### Providers

Eidolon supports multiple LLM providers:

#### OpenAI
```ruby
provider = Eidolon::Providers::OpenAI.new(
  api_key: 'your-openai-api-key',
  model: 'gpt-4o',
  organization: 'your-org-id'  # optional
)
```

#### Anthropic
```ruby
provider = Eidolon::Providers::Anthropic.new(
  api_key: 'your-anthropic-api-key',
  model: 'claude-3-5-sonnet-20241022',
  max_tokens: 4096
)
```

#### Google Gemini
```ruby
provider = Eidolon::Providers::Gemini.new(
  api_key: 'your-gemini-api-key',
  model: 'gemini-1.5-pro-002'
)
```

#### OpenRouter
```ruby
provider = Eidolon::Providers::OpenRouter.new(
  api_key: 'your-openrouter-api-key',
  model: 'openai/gpt-4o',
  site_url: 'https://yourapp.com',  # optional
  site_name: 'Your App'             # optional
)
```

### Tools

Create tools by subclassing `Eidolon::Tool`:

```ruby
class MyTool < Eidolon::Tool
  def initialize
    super(name: 'my_tool', description: 'Does something useful')
  end

  def properties
    [
      Eidolon::ToolProperty.new(
        name: 'param1',
        type: :string,
        description: 'A parameter',
        required: true
      )
    ]
  end

  def call(param1:)
    "Result: #{param1}"
  end
end
```

### System Prompts

Structure your agent instructions:

```ruby
prompt = Eidolon::SystemPrompt.new(
  background: [
    "You are a helpful assistant",
    "You specialize in answering questions"
  ],
  steps: [
    "Listen to the user's question",
    "Provide a clear, accurate answer",
    "Ask follow-up questions if needed"
  ],
  output_format: "Always be concise and helpful"
)
```

### Structured Output

Define structured output schemas using Ruby classes:

```ruby
class MyDataClass
  include Eidolon::StructuredOutput
  
  # Define properties with validation
  schema_property :field_name, 
    description: "Field description",
    required: true,
    type: "string",  # string, integer, number, boolean, array, object
    enum_values: ["option1", "option2"]  # optional
end

# Use with agents
result = agent.structured("Extract data from this text", MyDataClass)
puts result.field_name
```

**Key Features:**
- Automatic JSON schema generation
- Built-in validation with retry logic
- Support for all JSON Schema types
- Enum value validation
- Required field validation

### Attachments

Work with images and documents:

```ruby
# Images
image = Eidolon::Image.from_file('photo.jpg')          # From file
image = Eidolon::Image.from_url('http://example.com/img.jpg')  # From URL

# Documents (limited provider support)
doc = Eidolon::Document.from_file('document.pdf')     # From file

# Add to messages
message = Eidolon::UserMessage.new(content: "Analyze this")
  .add_attachment(image)
  .add_attachment(doc)
```

**Supported Formats:**
- **Images**: JPEG, PNG, GIF, WebP (provider dependent)
- **Documents**: PDF, TXT, MD (limited provider support)

## Provider Capabilities

| Feature                 | OpenAI | Anthropic | Gemini | OpenRouter* |
|-------------------------|--------|-----------|--------|-------------|
| **Chat Completion**     | ✅      | ✅         | ✅      | ✅           |
| **Function Calling**    | ✅      | ✅         | ✅      | ✅**         |
| **Structured Output**   | ✅      | ✅***      | ✅      | ✅**         |
| **Image Analysis**      | ✅      | ✅         | ✅      | ✅**         |
| **Document Processing** | ❌      | ✅         | ✅      | ❌**         |
| **Multiple Images**     | ✅      | ✅         | ✅      | ✅**         |
| **Image from URL**      | ✅      | ❌****     | ✅      | ✅**         |
| **Image from Base64**   | ✅      | ✅         | ✅      | ✅**         |
| **Retry Logic**         | ✅      | ✅         | ✅      | ✅           |
| **Error Handling**      | ✅      | ✅         | ✅      | ✅           |

**Notes:**
- *OpenRouter capabilities depend on the underlying model selected
- **OpenRouter inherits capabilities from the chosen model provider
- ***Anthropic structured output implemented via system prompts with validation
- ****Anthropic requires base64 encoding; URLs are automatically downloaded and converted

**Recommended Use Cases:**
- **OpenAI**: Best for image analysis and structured output with native JSON schema support
- **Anthropic**: Excellent for complex reasoning, document analysis, and comprehensive text processing
- **Gemini**: Great balance of capabilities with good document and image support
- **OpenRouter**: Access to multiple models through a single API; capabilities vary by model

## Configuration

### Environment Variables

Set your API keys for the providers you want to use:

```bash
export OPENAI_API_KEY=your_openai_api_key
export ANTHROPIC_API_KEY=your_anthropic_api_key
export GEMINI_API_KEY=your_gemini_api_key
export OPENROUTER_API_KEY=your_openrouter_api_key
```

### Development Setup

For development, copy the example environment file and add your API keys:

```bash
cp .env.example .env
# Edit .env and add your API keys
```

The gem includes dotenv support for easy development. Your `.env` file should look like:

```bash
# API Keys
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here
GEMINI_API_KEY=your_gemini_api_key_here
OPENROUTER_API_KEY=your_openrouter_api_key_here

# Optional OpenRouter settings
OPENROUTER_SITE_URL=https://yourapp.com
OPENROUTER_SITE_NAME=Your App Name
```

## Examples

Check the `examples/` directory for more detailed examples:

- `simple_agent.rb`: Basic agent without tools
- `youtube_agent.rb`: Agent with tool integration
- `multi_provider_examples.rb`: Examples showing all supported providers
- `structured_output_examples.rb`: Comprehensive structured output examples
- `simple_structured_output.rb`: Simple structured output example
- `attachment_examples.rb`: Comprehensive image and document processing examples
- `simple_image_chat.rb`: Simple image analysis example

## Development

# 1. Clone repo and setup
git clone <repo>
cd eidolon

# 2. Install dependencies
bundle install

# 3. Setup environment
cp .env.example .env
# Edit .env with your API keys

# 4. Start console
bin/console

# 5. Test with real API keys
agent = create_agent(:openai)
agent.chat("Hello!")


## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).