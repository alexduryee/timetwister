require "timetwister/version"
require "timetwister/parser"

module Timetwister

  	def self.parse(str, options={})

  		out = []

  		str.split(';').each do |semi|
  			semi.split(' and ').each do |conj|

  				# check for dates of form "Month Day(-Day), Year" before splitting on commas
  				# (removes certainty markers as to not jam the regex)
  				if conj.gsub(/[\?\[\]]/, '').match(/[JFMASOND][A-Za-z]*\.?\s[0-9]{1,2}(\s?-[0-9]{1,2})?\,\s[0-9]{4}/)
  					out << Parser.string_to_dates(conj, options)
  				else
  					conj.split(',').each do |comma|
  						out << Parser.string_to_dates(comma, options)
  					end
  				end
  			end
  		end

		return out

	end
end
