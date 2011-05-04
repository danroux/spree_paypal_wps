Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_paypal_wps'
  s.version     = '0.0.1'
  s.summary     = 'Integration for Paypal Website Payments Standard'
  s.description = ''
  s.required_ruby_version = '>= 1.8.7'

  s.author            = 'Amed Rodriguez'
  s.email             = 'amed@tractical.com'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.has_rdoc = true

  s.add_dependency('spree_core', '>= 0.50.1')
end
