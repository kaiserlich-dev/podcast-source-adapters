Gem::Specification.new do |spec|
  spec.name = "podcast_source_adapters"
  spec.version = "0.1.0"
  spec.summary = "Provider-neutral podcast discovery adapters"
  spec.authors = [ "Kaiserlich" ]
  spec.required_ruby_version = ">= 3.2"
  spec.files = Dir["lib/**/*", "README.md", "LICENSE"]
  spec.require_paths = [ "lib" ]
  spec.license = "MIT"
  spec.add_dependency "rss", ">= 0.3", "< 1"
end
