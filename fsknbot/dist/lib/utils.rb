
    #
    # taken from rbot Utils
    #

    def safe_exec(command, *args)
      IO.popen("-") { |p|
        if p
          return p.readlines.join("\n")
        else
          begin
            $stderr.reopen($stdout)
            exec(command, *args)
          rescue Exception => e
            puts "exec of #{command} led to exception: #{e.pretty_inspect}"
            Kernel::exit! 0
          end
          puts "exec of #{command} failed"
          Kernel::exit! 0
        end
      }
    end

