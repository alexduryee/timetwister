require "timetwister/version"
require "timetwister/parser"

module Timetwister

  	def self.parse(str, options={})

		dates = { :original_string => str, :index_dates => [], :date_start => nil, :date_end => nil,
			:date_start_full => nil, :date_end_full => nil, :inclusive_range => nil, :certainty => nil }

		# defensive check - we don't want to try to parse certain malformed strings
		# (otherwise dates get flipped and types get wacky)
		if str.include?('??')
			return dates
		end

		return Parser.string_to_dates(str, dates, options)

	end
end
