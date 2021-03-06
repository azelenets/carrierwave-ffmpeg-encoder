# frozen_string_literal: true

$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'carrierwave-ffmpeg-encoder'
  s.version     = '0.0.1'
  s.authors     = %w[rheaton azelenets]
  s.email       = %w[rachelmheaton@gmail.com andrew.zelenets@gmail.com]
  s.homepage    = "https://github.com/azelenets/carrierwave-ffmpeg-encoder"
  s.summary     = %q{CarrierWave extension that uses ffmpeg to transcode video and audio files.}
  s.description = %q{Transcodes to html5-friendly video/audio format.}
  s.license     = 'MIT'
  # s.rubyforge_project = 'carrierwave-ffmpeg-encoder'

  # s.files         = `git ls-files`.split("\n")
  s.files         = Dir["{lib}/**/*", "README.md"]
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w[lib]

  s.add_development_dependency 'rspec', '>= 3.3.0'
  s.add_development_dependency 'rake'

  s.add_runtime_dependency 'streamio-ffmpeg'
  s.add_runtime_dependency 'carrierwave'

  s.requirements << 'ruby, version 2.3 or greater'
  s.requirements << 'ffmpeg, version 0.11.1 or greater with libx256, libfdk-aac, libtheora, libvorbid, libvpx enabled'
end
