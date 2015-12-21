require "timetwister/version"
require "timetwister/parser"

module Timetwister

  	def self.parse(str, options={})

  		out = []
      str = rearrange_conjunctions(str)

  		str.split(';').each do |semi|
   			semi.split(/\sand\s|\s\&\s/i).each do |conj|

   				# check for dates of form "Month Day(-Day), Year" before splitting on commas
   				# (removes certainty markers as to not jam the regex)
   				if Parser.replace_ordinals(conj).gsub(/[\?\[\]]/, '').match(/[a-z]*\.?\s[0-9]{1,2}(\s?-[0-9]{1,2})?\,\s[0-9]{4}/i)
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

  # sometimes years are considered implicit in complex dates
  # e.g. "1900 January & February"
  # this rearranges them into complete atomic dates
  def self.rearrange_conjunctions(str)

    # if we don't have a complete year and month, call it quits
    if !str.match(/[0-9]{4}/) || !str.match(/[a-z]+/i)
      return str
    end

    year = str.match(/[0-9]{4}/)[0]
    month = str.match(/[a-z]+/i)[0]
    return_str = ''

    str.split(/\sand\s|\s\&\s/).each do |conj|

      if !conj.match(/[0-9]{4}/)
        conj << ' ' + year
      end

      if !conj.match(/[a-z]+/i)
        conj = month + ' ' + conj
      end

      return_str << ' and ' + conj
    end

    return return_str.sub(/\sand\s/, '')

  end
end
