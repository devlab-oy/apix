Gem::Specification.new do |s|
  s.name        = 'apix'
  s.version     = '0.0.1'
  s.date        = '2016-02-17'
  s.summary     = "Apix messaging Rest API client"
  s.description = "Client to interract with Apix messaging electronix invoicing API."
  s.authors     = ["Antti Jäppinen"]
  s.email       = 'antti@devlab.fi'
  s.files       = ["lib/apix.rb"]
  s.homepage    = 'https://github.com/devlab-oy/apix'
  s.license     = 'MIT'

  s.add_dependency 'nokogiri'
  s.add_dependency 'rest-client'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'codeclimate-test-reporter'
end
