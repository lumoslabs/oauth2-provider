spec = Gem::Specification.new do |s|
  s.name              = 'oauth2-provider'
  s.version           = '2.0.1'
  s.summary           = 'Simple OAuth 2.0 provider toolkit'
  s.author            = 'James Coglan'
  s.email             = 'james@songkick.com'
  s.homepage          = 'http://www.songkick.com'

  s.extra_rdoc_files  = %w(README.rdoc)
  s.rdoc_options      = %w(--main README.rdoc)

  s.files             = %w(README.rdoc) + Dir.glob("{spec,lib,example}/**/*")
  s.require_paths     = ['lib']

  s.add_dependency 'activerecord'
  s.add_dependency 'bcrypt', '~> 3.1'
  s.add_dependency 'json'
  s.add_dependency 'rack'

  s.add_development_dependency 'rspec', '~> 3.3.0'
  s.add_development_dependency 'sinatra', '>= 1.3.0'
  s.add_development_dependency 'thin'
  s.add_development_dependency 'factory_girl', '~> 2.0'
end
