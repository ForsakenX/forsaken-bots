class Sms < Meth::Plugin
  def pre_init
    @commands = [:sms]
    @users = {
      "methods" => "2013625531@messaging.sprintpcs.com"
    }
  end
  def sms m
    params = m.params
    unless to = params.shift
      m.reply "Missing `to' argument."
      return false
    end
    unless to = @users[to]
      m.reply "User does not exist."
      return false
    end
    unless message = params.join(' ')
      m.reply "Message is required!"
      return false
    end
    # send through gmail smtp
    EM::Protocols::SmtpClient.send({
      :host => "smtp.gmail.com",
      :domain => "localhost",
      :starttls => true,
      :auth => {
        :type => :plain,
        :username => "mr.daneilaquino@gmail.com",
        :password => "PASSWORD",
      },
      :from => "mr.danielaquino@gmail.com",
      :to => to,
      :headers => {
        "Subject" => "Testing",
      },
      :body => "testing...",
      :verbose => false
    })
  end
end
