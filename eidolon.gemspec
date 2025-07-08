Gem::Specification.new do |spec|
  spec.name          = "eidolon"
  spec.version       = "0.1.0"
  spec.authors       = ["Your Name"]
  spec.email         = ["your.email@example.com"]

  spec.summary       = "Ruby gem for creating LLM agents with OpenRouter integration"
  spec.description   = "A Ruby gem inspired by Neuron AI that allows you to create LLM agents with tool support using OpenRouter as the provider"
  spec.homepage      = "https://github.com/yourusername/eidolon"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "net-http", "~> 0.3"
  spec.add_dependency "json", "~> 2.6"

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "dotenv", "~> 2.8"
end