

module TracLang

  # Class for storing forms under their names.
  class Block

    # Reads block from the given file.  The file may have any valid TRAC
    # commands in it, as well as ordinary text, which will be ignored.
    # The options for trace and savedir will be inherited from the Dispatch
    # calling this method.
    def self.read(filename, **options)
      e = Executor.new(Dispatch.new(options))
      File.new(filename, 'r') do |f|
        break unless e.load(filename, $., f.gets)
      end
    end
    
    # Writes block to the given file.  Block is written with the following:
    # 1. Version of the TRAC Language processor
    # 2. Current time
    # 3. #(DS) commands for each bound form
    # 4. #(SS) commands for each bound form that has segments
    # 5. A mix of #(CN) and #(CS) commands to position the form pointer
    def self.write(filename, bindings)
      File.new(filename, "w") do |f|
        f.puts "TRAC Lang Version #{VERSION}"
        f.puts "Saved: #{Time.now}"
        f.puts
        bindings.each { |name, form| f.puts(form.to_trac(name)) }
      end
    end
    
    # Deletes given file.
    def self.delete(filename)
      begin
        File.delete(filename)
      rescue Errno::ENOENT
        # ignore non-existant file
      end
    end
    
  end
  
end
