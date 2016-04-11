# encoding: utf-8

class Utilities

	# walk through a hash and transforms all ints to strings
	# input: a hash
	# output: same hash, but with all Fixnums converted to strings
	def self.stringify_values(hash)
		hash.each do |k,v|
			if v.is_a?(Fixnum)
				hash[k] = v.to_s
			end
		end

		return hash
	end

	# return MODS certainty from a date string
	# input: freetext date string
	# output: string representing the date certainty
	def self.return_certainty(str)

		# order of precedence, from least to most certain:
	    # 1) questionable dates
	    # 2) approximate dates
	    # 3) inferred dates

	    if str.include?('?')
	      return 'questionable'
	    end

	    if str.downcase.include?('ca') || \
	      str.downcase.include?('approx')
	      return 'approximate'
	    end

	    if str.include?('[') || str.include?(']')
	      return 'inferred'
	    end

	    return nil
	end

	# replaces ordinal numbers in a date string with flat numbers
	# input: freetext date string
	# output: same string, but with ordinals replaced by numbers
	def self.replace_ordinals(str)

		work_str = str.clone

		ordinals = {
			# replace fulltext ordinals with numbers
			'first' => '1',
			'second' => '2',
			'third' => '3',
			'fourth' => '4',
			'fifth' => '5',
			'sixth' => '6',
			'seventh' => '7',
			'eighth' => '8',
			'ninth' => '9',
			'tenth' => '10',
			'eleventh' => '11',
			'twelfth' => '12',
			'thirteenth' => '13',
			'fourteenth' => '14',
			'fifteenth' => '15',
			'sixteenth' => '16',
			'seventeenth' => '17',
			'eighteenth' => '18',
			'nineteenth' => '19',
			'twentieth' => '20',
			'twenty-' => '2',
			'thirtieth' => '30',
			'thirty-' => '3',

			# replace numeric ordinals with plain numbers
			'1st' => '1',
			'2nd' => '2',
			'3rd' => '3',
			'3d' => '3',
			'4th' => '4',
			'5th' => '5',
			'6th' => '6',
			'7th' => '7',
			'8th' => '8',
			'9th' => '9',
			'0th' => '0'
		}

		ordinals.each do |key, value|
			work_str.gsub!(Regexp.new(key), value)
		end

		return work_str
	end

	# replaces non-english language months with english months
	# input: freetext date string
	# output: same string, but with months replaced by english months
	def self.language_to_english(str)

		work_str = str.clone

		languages = {

			# french
			'janvier' => 'January',
			'février' => 'February',
			'mars' => 'March',
			'avril' => 'April',
			'mai' => 'May',
			'juin' => 'June',
			'juillet' => 'July',
			'août' => 'August',
			'septembre' => 'September',
			'octobre' => 'October',
			'novembre' => 'November',
			'décembre' => 'December',

			# spanish
			'enero' => 'January',
			'febrero' => 'February',
			'marzo' => 'March',
			'abril' => 'April',
			'mayo' => 'May',
			'junio' => 'June',
			'julio' => 'July',
			'agosto' => 'August',
			'septiembre' => 'September',
			'octubre' => 'October',
			'noviembre' => 'November',
			'diciembre' => 'December',

			# italian
			'gennaio' => 'January',
			'febbraio' => 'February',
			'marzo' => 'March',
			'aprile' => 'April',
			'maggio' => 'May',
			'giugno' => 'June',
			'luglio' => 'July',
			'agosto' => 'August',
			'settembre' => 'September',
			'ottobre' => 'October',
			'novembre' => 'November',
			'dicembre' => 'December',

			# german
			'januar[^y]' => 'January',
			'februar[^y]' => 'February',
			'märz' => 'March',
			'april' => 'April',
			'mai' => 'May',
			'juni' => 'June',
			'juli' => 'July',
			'august' => 'August',
			'september' => 'September',
			'oktober' => 'October',
			'november' => 'November',
			'dezember' => 'December'
		}

		languages.each do |key, value|
			work_str.gsub!(/#{key}/i, value)
		end

		return work_str
	end

	# returns the days in a given month
	# input: a month and year (int, or numeric strings)
	# output: the number of days in that month in that year
	def self.days_in_month(month,year)
		month = month.kind_of?(String) ? month.to_i : month
		year = year.kind_of?(String) ? year.to_i : year
		days = {
			1 => 31,
			2 => leap_year?(year) ? 29 : 28,
			3 => 31,
			4 => 30,
			5 => 31,
			6 => 30,
			7 => 31,
			8 => 31,
			9 => 30,
			10 => 31,
			11 => 30,
			12 => 31
		}
		days[month]
	end


	# transforms a datetime object into an int
	# input: datetime
	# output: same datetime, transformed into an int
	def self.datetime_comparitor(datetime)
		d = datetime.to_s
		d.gsub!(/[^\d]/,'')
		return d.to_i
	end


	# determines if a year is leap or not
	# input: a year as an int or string
	# output: boolean of whether the year is leap or not
	def self.leap_year?(year)
		year = (year.kind_of? String) ? year.to_i : year
		if year % 400 == 0
			return true
		elsif year % 100 == 0
			return false
		elsif year % 4 == 0
			return true
		else
			return false
		end
	end

	# removes sub-strings that do not contain parsable data
	# input: freetext string
	# output: same string, ready for the parser
	def self.clean_string(string)
		r = @regex_tokens
		# remove n.y. and variants from beginning of string
		substrings = [
			/\[n\.?y\.?\]/,
			/[\[\]\(\)]/,
			/[\.\,\)\;\:]*$/,
			/\?/,
			/approx\.?(imately)?/i,
			/\s#{regex_tokens[:circa]}\s/,
			/^#{regex_tokens[:circa]}\s/,
			Regexp.new("([\,\;\s(and)]{0,4}#{regex_tokens[:nd]})?$")
		]

		# transform seasons to months
		string.gsub!(/[Ww]inter/, " January 1 - March 20 ")
		string.gsub!(/[Ss]pring/, " March 20 - June 21 ")
		string.gsub!(/[Ss]ummer/, " June 21 - September 23 ")
		string.gsub!(/[Aa]utumn/, " September 23 - December 22 ")
		string.gsub!(/[Ff]all/, " September 23 - December 22 ")

		# remove days of the week
		dow = [/[Ss]unday,?\s+/, /[Mm]onday,?\s+/, /[Tt]uesday,?\s+/, /[Ww]ednesday,?\s+/, /[Tt]hursday,?\s+/, /[Ff]riday,?\s+/, /[Ss]aturday,?\s+/]
		dow.each {|d| string.gsub!(d, '')}

		# remove times of day
		tod = [/[Mm]orning,?\s+/, /[Aa]fternoon,?\s+/, /[Ee]vening,?\s+/, /[Nn]ight,?\s+/]
		tod.each {|t| string.gsub!(t, '')}

		# remove single question marks
		string.gsub!(/([0-9])\?([^\?])/,'\1\2')

		substrings.each { |s| string.gsub!(s,'') }
		string.strip!
		return string
	end

	# Removes the first 4-digit number found in the string and returns it
	def self.extract_year(string)
		year = string.match(/\d{4}/).to_s
		string.gsub!(Regexp.new(year),'')
		year
	end

	# regexes used by parser to detect various date forms
	def self.regex_tokens
		return {
			# 1969, [1969], c1969
			:year => '[\[\sc\(]{0,3}[0-2][0-9]{3}[\]\s\.\,;\?\)]{0,3}',
			# - or 'to'
			:range_delimiter => '\s*((\-)|(to))\s*',
			# , or ;
			:list_delimiter => '\s*[\,\;]\s*',
			# , or ;
			:range_or_list_delimiter => '\s*([\,\;]|((\-)|(to)))\s*',
			# n.d., undated, etc.
			:nd => '[\[\s]{0,2}\b([Uu]+ndated\.?)|([nN]o?\.?\s*[dD](ate)?\.?)\b[\s\]\.]{0,3}',
			# 1960s, 1960's
			:decade_s => '[\[\s]{0,2}[0-9]{3}0\'?s[\]\s]{0,2}',

			# 1970-75
			:year_range_short => '\s*[0-9]{4}\s?\-\s*(([2-9][0-9])|(1[3-9]))\s*',

			# 196-
			:decade_aacr => '[0-9]{3}\-',
			# named months, including abbreviations (case insensitive)
			:named_month => '\s*(?i)\b((jan(uary)?)|(feb(ruary)?)|(mar(ch)?)|(apr(il)?)|(may)|(jun(e)?)|(jul(y)?)|(aug(ust)?)|(sep(t|tember)?)|(oct(ober)?)|(nov(ember)?)|(dec(ember)?))\b\.?\s*',
			# circa, ca. - also matches 'c.', which is actually 'copyright', but is still not something we need to deal with
			:circa => '\s*[Cc](irc)?a?\.?\s*',
			# early, late, mid-
			:decade_qualifier => '(([Ee]arly)|([Mm]id)|([Ll]ate))\-?',
			# 06-16-1972, 6-16-1972
			:numeric_date_us => '(0?1)|(0?2)|(0?3)|(0?4)|(0?5)|(0?6)|(0?7)|(0?8)|(0?9)|1[0-2][\-\/](([0-2]?[0-9])|3[01])[\-\/])?[12][0-9]{3}',
			# 1972-06-16
			:iso8601 => '[0-9]{4}\-[0-9]{2}\-[0-9]{2}',
			:iso8601_full => '[0-9]{4}((\-[0-9]{2})(\-[0-9]{2})?)?',
			:iso8601_month => '[0-9]{4}\-[0-9]{2}',
			:anchor_start => '^[^\w\d]*',
			:anchor_end => '[^\w\d]*$',
			:optional_comma => '[\s\,]*',
			:day_of_month => '\s*(([0-2]?[0-9])|(3[0-1]))\s*'
		}
	end
end
