require 'net/http'
require 'uri'
class TinyUrl

	@@tinyurl = URI.parse "http://tinyurl.com/api-create.php"

	attr_accessor :tiny, :original, :post

	def initialize url
		@original = url
		@post = { 'url' => @original }
		@tiny = Net::HTTP.post_form( @@tinyurl, @post).body
	end

end
