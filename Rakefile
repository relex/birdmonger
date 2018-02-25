require "bundler/gem_tasks"

task :assemble_jar do
  `sbt clean assembly`
end

task :remove_jar do
  FileUtils.rm('lib/birdmonger.jar')
end

Rake::Task[:build].enhance(%i(assemble_jar)) { Rake::Task[:remove_jar].invoke }
Rake::Task[:clean].enhance { Rake::Task[:remove_jar].invoke }

task :default => :spec
