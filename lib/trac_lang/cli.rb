require 'thor'

module TracLang

  class CLI < Thor
  
    desc 'trac_lang FILE_LIST', 'Run TRAC using the files provided'
    method_option :save_dir, :aliases => '-d', :desc => 'Directory for saving blocks'
    method_option :exit_on_eof, :aliases => '-x', :desc => 'Exit TRAC after processing last file'
    method_option :trace, :aliases => '-t', :desc => 'Turn trace on'
    def command(*files)
      begin 
        d = TracLang::Dispatch.new(options)
        e = TracLang::Executor.new(d)
        catch :done do
          files.each do |file|
            File.open(file) do |f|
              e.load(file, __LINE__, f.gets)
            end
          end
          exit if options[:exit_on_eof]
          e.prompt
        end
        puts 'Exiting...'
        puts
      rescue => error
        puts "An unexpected error occured while running TRAC Lang"
        puts "  #{error}\n"
        exit(false)
      end      
    end
    
    default_task :command
    
  end

end