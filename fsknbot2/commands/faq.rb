
IrcCommandManager.register 'faq',
"faq [list] => List all faq names.  "+
"faq [get] <name> => Show the faq for <name>.  "+
"faq set|add <name> <answer> => Adds a faq to the list.  "+
"faq del <name> => Removes a faq.  "

IrcCommandManager.register 'faq' do |m|
  FAQ.run(m)
end

require 'yaml'
class FAQ
  class << self

    @@db = "#{ROOT}/db/faq.yaml"

    def run m
      switch = m.args.shift
      case switch
      when "",nil
        m.reply IrcCommandManager.help[ 'faq' ]
      when "list"
        m.reply "http://fly.thruhere.net/faq.txt"
        #list m
      when "set","add"
        set m
      when "del"
        del m
      when "get"
        get m, m.args.shift
      else
        get m, switch
      end
    end

    def load
      (FileTest.exists?(@@db) && YAML.load_file(@@db)) || {}
    end

    def list m
      m.reply self.load.keys.sort.join(', ')
    end

    def get m, name
      faq = self.load
      return m.reply("Missing <name>.") if name.nil?
      return m.reply("faq `#{name}' does not exist.") unless faq[name]
      m.reply faq[name]
    end

    def set m
      faq = self.load
      return m.reply("Missing <name>.") unless name = m.args.shift
      return m.reply("Missing <answer>.") unless answer = m.args.join(' ')
      faq[name] = answer
      save faq
      m.reply "Saved"
    end

    def del m
      faq = self.load
      return m.reply("Missing <name>.") unless name = m.params.shift
      return m.reply("faq `#{name}' does not exist.") if faq[name].nil?
      faq.delete name
      save del
      m.reply "Deleted"
    end

    def save faq
      f = File.open(@@db,'w+')
      YAML.dump(faq,f)
      f.close
    end
  
  end
end
