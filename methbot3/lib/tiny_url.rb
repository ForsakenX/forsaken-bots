
require 'open-uri'
class TinyUrl

	@@tinyurl = "http://tinyurl.com/api-create.php?url="

	attr_accessor :tiny, :original

	def initialize url
		@original = url
		@tiny = open( @@tinyurl + url ).read
	end

end

