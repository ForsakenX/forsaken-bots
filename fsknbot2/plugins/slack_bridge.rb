# vim: set ts=2 sw=2 et :

require 'irc_handle_line'

$send_to_slack = lambda do |user,text,channel="#freenode-bridge"|
  text.gsub! /\n/, ' ' # post data wont be happy with new lines in it
  puts "send_to_slack: user=#{user}, text=#{text}, channel=#{channel}"
  `
    curl \
      -s \
      -X POST --data-urlencode \
      'payload={"channel":"#{channel}","username":"#{user} @ freenode","text":"#{text}","icon_emoji":":ghost:"}' \
      "#{$slack_incoming_hook}"
  `
end

IrcHandleLine.events[:message].register do |args|
  next if args[:to].downcase != '#forsaken'
  next if args[:from].downcase =~ /freenode/
  next if args[:from].downcase =~ / @ slack/ # we set this later
  puts "forwarding message to slack.com"
  $send_to_slack.call args[:from], args[:message]
end

$send_user_list_to_slack = lambda do
  users = IrcUser.nicks.
            select{|n|
              n !~ / @ slack/ &&
              n !~ /ChanServ/i &&
              n !~ /#{$nick}/i
            }.join(", ")
  next if users.empty?
  next if users == $last_users_list
  $last_users_list = users
  $send_to_slack.call "FsknBot", "Users: #{users}"
end

%w{ join part }.each do |event|
  IrcHandleLine.events[event.to_sym].register do |channel,nick|
    next if channel != "#forsaken"
    #next if nick.downcase == "fsknbot"
    puts "forwarding #{event} to slack.com"
    $send_to_slack.call "FsknBot", "#{nick} has #{event}ed #{channel}"
    $send_user_list_to_slack.call
  end
end

IrcHandleLine.events[:end_who_list].register do
  $send_user_list_to_slack.call
end

IrcConnection.events[:privmsg].register do |targets,messages|
  next unless targets.include? "#forsaken"
  puts "forwarding message to slack.com"
  $send_to_slack.call "FsknBot", [messages].flatten.join("\n")
end

require 'evma_httpserver'

class SlackHttpListener < EM::Connection

  include EM::HttpServer

  def post_init
    super
    no_environment_strings
    puts "Slack HTTP Listener: New Connection From: ..."
  end

  def unbind
    super
    puts "Slack HTTP Listener: Lost Connection From: ..."
  end

  def receive_data data
    puts "Slack HTTP Listener: Received data From:  ..."
    puts "Slack HTTP Listener: Data = #{data}"
    super data
  end

  def send_data data
    puts "Slack HTTP Listener: Sending data to: ..."
    puts "Slack HTTP Listener: Data = #{data}"
    super data
  end

  def process_http_request
    #   @http_protocol
    #   @http_request_method
    #   @http_cookie
    #   @http_if_none_match
    #   @http_content_type
    #   @http_path_info
    #   @http_request_uri
    #   @http_query_string
    #   @http_post_content
    #   @http_headers

    puts "slack bridge reciever:"
    puts [
      :@http_request_method, :@http_cookie,
      :@http_if_none_match, :@http_content_type,
      :@http_path_info, :@http_request_uri,
      :@http_query_string, :@http_post_content,
      :@http_headers
    ].map{|x|
      "#{x} => #{instance_variable_get(x).inspect}"
    }.join("\n")
    puts "---"

    # keys: token,team_id,team_domain,service_id,channel_id,
    #       channel_name,timestamp,user_id,user_name,text

    unless @http_post_content
      puts "slack @http_post_content was nil?"
      return
    end

    p = @http_post_content.split('&').
        inject({}){|h,i|k,v=i.split('='); h[k.to_sym]=v; h}

    puts "slack post content:"
    puts p.inspect.to_s
    puts "---"

    puts "token=#{p[:token]}"
    puts "user=#{p[:user_name]}"
    puts "text=#{p[:text]}"

    # stop infinite loop
    if p[:user_name] == 'slackbot'
      respond
      return
    end

    # strip text of weird slack url formatting
    require 'cgi'
    text = CGI::unescape p[:text]
    text.gsub!(/<(https?:[^>|]*)(|[^>]*)?>/,'\1')

    # create fake user so IrcChatMsg doesn't block us
    nick = "#{p[:user_name]} @ slack"
    IrcUser.create({
      :nick => nick,
      :host => "[slack-user]"
    })

    # outgoing webhook for #freenode-bridge relay
    if p[:token] == $slack_bridge_token

      # send message to channel
      IrcConnection.privmsg_raw '#forsaken',
        "#{nick}: #{text}"

      # generate a new chat message so bot can parse out commands
      # the privmsg listener registered above will relay response
      IrcHandleLine.events[:message].call({
        :time => Time.now,
        :to   => '#forsaken',
        :from => nick,
        :type => 'PRIVMSG',
        :line => "-- stub value for messages from slack.com",
        :message => text
      })

    end

    # outgoing webhook for #general chat bot integration
    if p[:token] == $slack_general_bot_token

      IrcChatMsg.new({
        :time => Time.now,
        :to   => '#forsaken',
        :from => nick,
        :type => 'PRIVMSG',
        :line => "-- stub value for messages from slack.com",
        :message => text,
        :replier => Proc.new { |text|
          $send_to_slack.call( 'FsknBot', text, '#general' )
        }
      })

    end

    #
    respond

  end

  # let slack know that everything went ok
  def respond
    response = EM::DelegatedHttpResponse.new(self)
    response.status = 200
    response.content_type 'text/html'
    response.content = ''
    response.send_response
  end

end

$run_observers << Proc.new {
  EM.start_server '0.0.0.0', 8080, SlackHttpListener
}

