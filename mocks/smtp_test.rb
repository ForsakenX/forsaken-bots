#!/usr/bin/env ruby
require 'rubygems'
require 'eventmachine'
EM::Protocols::SmtpClient.send({
  :host => "smtp.gmail.com",
  :domain => "localhost",
  :starttls => true,
  :auth => {
    :type => "plain",
    :username => "mr.daneilaquino@gmail.com",
    :password => "PASSWORD",
  },
  :from => "mr.danielaquino@gmail.com",
  :to => "2013625531@messaging.sprintpcs.com",
  :headers => {
    "Subject" => "Testing",
  },
  :body => "testing...",
  :verbose => true
})
