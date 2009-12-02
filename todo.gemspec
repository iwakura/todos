Gem::Specification.new do |spec|
  spec.name = 'todo'
  spec.version = '0.0.1'
  spec.executables = 'todo'
  spec.add_dependency 'sqlite3-ruby', '>=1.2.4'
  spec.add_dependency 'sequel', '>=3.6.0'
  spec.summary = 'Interactive CLI tool for managing list of tasks'
  spec.description = <<-EOF
  Interactive command line application for managing list of tasks.
  Allow create new tasks, remove tasks, mark task as done and
  filter tasks on project or context.
  EOF
  spec.files = Dir['lib/**/*.rb'] + Dir['bin/*']
  spec.has_rdoc = false
  spec.requirements << 'sqlite3-3.6.19 or greater'
  spec.email = 'taro@mail333.com'
  spec.author = 'Iwakura Taro'
end
