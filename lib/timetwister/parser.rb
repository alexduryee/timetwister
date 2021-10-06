# encoding: utf-8

require 'date'
require 'timetwister/utilities'

class Parser

	def self.string_to_dates(str, options)
		@string = str.clone
		@options = options

		@dates = { :original_string => str, :index_dates => [], :date_start => nil, :date_end => nil,
			:date_start_full => nil, :date_end_full => nil, :inclusive_range => nil, :certainty => nil }

		@regex_tokens = Utilities.regex_tokens

		# defensive checks against very malformed date strings
		if str.include?('??')
			return @dates
		end

		# perform this here, before the string gets purged of certainty indicators
		@dates[:certainty] = Utilities.return_certainty(@string)

		# normalize the string into the parser's preferred form
		@string = Utilities.clean_string(@string)
		@string = Utilities.language_to_english(@string)
		@string = Utilities.replace_ordinals(@string)

		# parse!
		self.match_replace

		# if there are any future dates, return an empty hash
		if @dates[:index_dates] != [] && @dates[:index_dates].last > Time.now.year
			return { :original_string => @string, :index_dates => [], :keydate => nil, :keydate_z => nil, :date_start => nil, :date_end => nil,
				:date_start_full => nil, :date_end_full => nil, :inclusive_range => nil, :certainty => nil }
		end

		if @dates[:date_start] && !@dates[:date_end] && !(@dates[:test_data] == 150 || @dates[:test_data] == 160)
			@dates[:date_end] = @dates[:date_start]
		end

		@dates = Utilities.stringify_values(@dates)
		add_full_dates

		return @dates
	end

	def self.match_replace
		match_replace_clusters.each do |c|
			match_patterns = (c[:match].kind_of? Array) ? c[:match] : [c[:match]]
			match_patterns.each do |p|
				match_test = @regex_tokens[:anchor_start] + p + @regex_tokens[:anchor_end]
				if @string.match(match_test)
					@dates[:test_data] = c[:id]
					if c[:proc]
						# clone string to avoid changing it via in-place methods used in Procs
						work_string = @string.clone
						c[:proc].call(work_string, c[:arg])
					end
					break
				end
			end
		end
	end


	def self.match_replace_clusters
		r = @regex_tokens

		# extend regex_tokens for common complex formats

		# July 4, 1776
		r[:date_month_day_year] = "(#{r[:circa]})?#{r[:named_month]}#{r[:day_of_month]}#{r[:optional_comma]}#{r[:year]}"
		# July 1776
		r[:date_month_year] = "(#{r[:circa]})?#{r[:named_month]}#{r[:optional_comma]}#{r[:year]}"
		# 1776 July 4
		r[:date_year_month_day] = "(#{r[:circa]})?#{r[:year]}#{r[:optional_comma]}#{r[:named_month]}#{r[:day_of_month]}"
		# 1776 4 July
		r[:date_year_day_month] = "(#{r[:circa]})?#{r[:year]}#{r[:optional_comma]}#{r[:day_of_month]}#{r[:named_month]}"
		# 4 July 1776
		r[:date_day_month_year] = "(#{r[:circa]})?#{r[:day_of_month]}#{r[:named_month]}#{r[:optional_comma]}#{r[:year]}"
		# 1776 July
		r[:date_year_month] = "(#{r[:circa]})?#{r[:year]}#{r[:optional_comma]}#{r[:named_month]}"

		match_replace = []

		# NOTE: :match values will be converted to regular expressions
		#   and anchored at the beginning and end of test string.
		#   Leading and trailing punctuation will be ignored

		# options[:force_8601] == true will force '2001-02' to be treated as February 2001 rather than 2001-2002
		#   and will handle ISO8601 ranges, e.g. 2001-02/2001-12
		if @options[:force_8601]
			match_replace << {
				:match => "#{r[:iso8601_full]}\\/#{r[:iso8601_full]}",
				:proc => proc_8601_range,
				:id => 10
			}
			match_replace << {
				:match => "#{r[:iso8601_month]}",
				:proc => proc_month_year_single,
				:id => 20
			}
		end

		# ISO 8601 (full dates only - see note on options[:force_8601] above)
		match_replace << {
			:match => "#{r[:iso8601]}",
			:proc => proc_full_date_single,
			:id => 30
		}

		# ISO 8601 ranges (full dates only - see note on options[:force_8601] above)
		match_replace << {
			:match => "#{r[:iso8601]}\\/#{r[:iso8601]}",
			:proc => proc_8601_range,
			:id => 40
		}

		# matches any number of 4-digit years separated by a single range or list delimiter
		match_replace << {
			:match => "((#{r[:year]})|(#{r[:year_range_short]}))(#{r[:range_or_list_delimiter]}((#{r[:year]})|(#{r[:year_range_short]})))+",
			:proc => proc_year_range_list_combo,
			:id => 60
		}

		# 1969, [1969], c1969
		# anti-matches the range delimiter as to not override id 150/160
		match_replace << {
			:match => [
								"(#{r[:circa]})?[^#{r[:range_delimiter]}]#{r[:year]}([\\,\\;\\s(and)]{1,3}#{r[:nd]})?",
								"^#{r[:year]}$"],
			:proc => proc_single_year,
			:id => 70
		}

		# "July 4 1976 - Oct 1 1981"
		# "4 July 1976 - 1 Oct 1981"
		# "1976 July 4 - 1981 Oct 1"
		# "1976 4 July - 1981 1 Oct"
		match_replace << {
			:match => [
				"#{r[:date_month_day_year]}#{r[:range_delimiter]}#{r[:date_month_day_year]}",
				"#{r[:date_day_month_year]}#{r[:range_delimiter]}#{r[:date_day_month_year]}",
				"#{r[:date_year_month_day]}#{r[:range_delimiter]}#{r[:date_year_month_day]}",
				"#{r[:date_year_day_month]}#{r[:range_delimiter]}#{r[:date_year_day_month]}",
			],
			:proc => proc_full_date_single_range,
			:id => 80
		}

		# "1976 July - 1981 Oct"
		# "July 1976 - Oct 1981"
		match_replace << {
			:match => [
				"(#{r[:circa]})?#{r[:date_year_month]}#{r[:range_delimiter]}(#{r[:circa]})?#{r[:date_year_month]}",
				"(#{r[:circa]})?#{r[:date_month_year]}#{r[:range_delimiter]}(#{r[:circa]})?#{r[:date_month_year]}"
			],
			:proc => proc_full_date_single_range,
			:arg => 'month',
			:id => 100
		}



		# 1969-1977
		match_replace << {
			:match => "(#{r[:circa]})?#{r[:year]}#{r[:range_delimiter]}(#{r[:circa]})?#{r[:year]}",
			:proc => proc_year_range,
			:id => 120
		}

		# 1960-1980s
		match_replace << {
			:match => "(#{r[:circa]})?#{r[:year]}#{r[:range_delimiter]}#{r[:decade_s]}",
			:proc => proc_range_year_to_decade,
			:id => 130
		}

		# 1960s-1981
		match_replace << {
			:match => "(#{r[:circa]})?\\s?#{r[:decade_s]}#{r[:range_delimiter]}(#{r[:circa]})?\\s?#{r[:year]}",
			:proc => proc_year_range,
			:id => 140
		}

		# 1969-72
		match_replace << {
			:match => "(#{r[:circa]})?#{r[:year_range_short]}",
			:proc => proc_year_range_short,
			:id => 145
		}

		# 1969- (e.g. after 1969)
		match_replace << {
			:match => "(#{r[:circa]})?\\s?#{r[:year]}#{r[:range_delimiter]}",
			:proc => proc_single_year,
			:arg => 'start',
			:id => 150
		}

		# -1969 (e.g. before 1969) - treat as single
		match_replace << {
			:match => "#{r[:range_delimiter]}(#{r[:circa]})?\\s?#{r[:year]}",
			:proc => proc_single_year,
			:arg => 'end',
			:id => 160
		}

		# nd, n.d., undated, Undated...
		# note that :id never manifests anywhere (no hash to put it into)
		# so the :test_data for undated is nil
		match_replace << {
			:match => "#{r[:nd]}",
			:proc => nil,
			:id => 170
		}

		# 1970's, 1970s
		match_replace << {
			:match => "(#{r[:circa]})?#{r[:decade_s]}",
			:proc => proc_decade_s,
			:id => 180
		}

		# 1970s - 1980s, etc.
		match_replace << {
			:match => "(#{r[:circa]})?\\s?#{r[:decade_s]}#{r[:range_delimiter]}(#{r[:circa]})?#{r[:decade_s]}",
			:proc => proc_decade_s_range,
			:id => 190
		}

		# July 4 1976
		# 4 July 1976
		# 1976 July 4
		# 1976 4 July
		# (with or without optional commas)
		match_replace << {
			:match => [
				"#{r[:date_month_day_year]}",
				"#{r[:date_day_month_year]}",
				"#{r[:date_year_month_day]}",
				"#{r[:date_year_day_month]}"
			],
			:proc => proc_full_date_single,
			:id => 200
		}


		# December 1941
		# 1941 December
		# (with or without optional commas)
		match_replace << {
			:match => [
				"(#{r[:circa]})?#{r[:date_month_year]}",
				"(#{r[:circa]})?#{r[:date_year_month]}"
			],
			:proc => proc_month_year_single,
			:id => 220
		}


		# Jun-July 1969
		# 1969 Jun-July
		match_replace << {
			:match => [
				"(#{r[:circa]})?#{r[:named_month]}#{r[:range_delimiter]}(#{r[:circa]})?#{r[:named_month]}#{r[:optional_comma]}#{r[:year]}",
				"(#{r[:circa]})?#{r[:year]}#{r[:optional_comma]}#{r[:named_month]}#{r[:range_delimiter]}(#{r[:circa]})?#{r[:named_month]}",
			],
			:proc => proc_single_year_month_range,
			:id => 230
		}


		# Feb. 1-20, 1980
		# 1980 Feb. 1-20
		# 1980 1-20 Feb.
		match_replace << {
			:match => [
				"(#{r[:circa]})?#{r[:named_month]}#{r[:day_of_month]}#{r[:range_delimiter]}#{r[:day_of_month]}#{r[:optional_comma]}#{r[:year]}",
				"(#{r[:circa]})?#{r[:year]}#{r[:optional_comma]}#{r[:named_month]}#{r[:day_of_month]}#{r[:range_delimiter]}#{r[:day_of_month]}",
				"(#{r[:circa]})?#{r[:year]}#{r[:optional_comma]}#{r[:day_of_month]}#{r[:range_delimiter]}#{r[:day_of_month]}#{r[:named_month]}",
				"(#{r[:circa]})?#{r[:day_of_month]}#{r[:range_delimiter]}#{r[:day_of_month]}#{r[:named_month]}#{r[:optional_comma]}#{r[:year]}"
			],
			:proc => proc_single_month_date_range,
			:id => 240
		}


		# Early 1960's, mid-1980s, late 1950's, etc.
		match_replace << {
			:match => "(#{r[:circa]})?#{r[:decade_qualifier]}\\s?#{r[:decade_s]}",
			:proc => proc_decade_s_qualified,
			:id => 250
		}


		# 19--, 18--, 18--?, etc.
		match_replace << {
			:match => "(#{r[:circa]})?[1-2][0-9]\-{2}",
			:proc => proc_century_with_placeholders,
			:id => 290
		}

		# Jan 2-Dec 31 1865
		# 1865 Jan 2-Dec 31
		match_replace << {
			:match => [
				"(#{r[:circa]})?#{r[:named_month]}#{r[:day_of_month]}#{r[:range_delimiter]}(#{r[:circa]})?#{r[:named_month]}#{r[:day_of_month]}#{r[:optional_comma]}#{r[:year]}",
				"(#{r[:circa]})?#{r[:year]}#{r[:optional_comma]}#{r[:named_month]}#{r[:day_of_month]}#{r[:range_delimiter]}(#{r[:circa]})?#{r[:named_month]}#{r[:day_of_month]}",
				"(#{r[:circa]})?#{r[:day_of_month]}#{r[:named_month]}#{r[:range_delimiter]}(#{r[:circa]})?#{r[:day_of_month]}#{r[:named_month]}#{r[:optional_comma]}#{r[:year]}"
				],
			:proc => proc_year_with_dates,
			:id => 310
		}

		# 1863 Aug 7-1866 Dec
		match_replace << {
			:match => [
				"(#{r[:circa]})?#{r[:year]}#{r[:named_month]}#{r[:day_of_month]}#{r[:range_delimiter]}(#{r[:circa]})?#{r[:year]}#{r[:named_month]}",
				"(#{r[:circa]})?#{r[:day_of_month]}#{r[:named_month]}#{r[:year]}#{r[:range_delimiter]}(#{r[:circa]})?#{r[:named_month]}#{r[:year]}",
				"(#{r[:circa]})?#{r[:named_month]}#{r[:day_of_month]}#{r[:range_delimiter]}(#{r[:circa]})?#{r[:named_month]}#{r[:year]}",
				"(#{r[:circa]})?#{r[:named_month]}#{r[:year]}#{r[:range_delimiter]}(#{r[:circa]})?#{r[:named_month]}#{r[:day_of_month]}#{r[:optional_comma]}#{r[:year]}",
				"(#{r[:circa]})?#{r[:year]}#{r[:named_month]}#{r[:range_delimiter]}(#{r[:circa]})?#{r[:year]}#{r[:named_month]}#{r[:day_of_month]}"
				],
			:proc => proc_full_with_year_month,
			:id => 330
		}

		# 1942 November-1943
		# 1943-1944 November
		# November 1942-1943
		# 1942-November 1943
		match_replace << {
			:match => [
			 "(#{r[:circa]})?#{r[:year]}#{r[:named_month]}#{r[:range_delimiter]}(#{r[:circa]})?#{r[:year]}",
			 "(#{r[:circa]})?#{r[:year]}#{r[:range_delimiter]}(#{r[:circa]})?#{r[:year]}#{r[:named_month]}",
			 "(#{r[:circa]})?#{r[:named_month]}#{r[:year]}#{r[:range_delimiter]}(#{r[:circa]})?#{r[:year]}",
			 "(#{r[:circa]})?#{r[:year]}#{r[:range_delimiter]}(#{r[:circa]})?#{r[:named_month]}#{r[:year]}"
				],
				:proc => proc_year_range_single_date,
				:id => 340
		}

		# 01/31/1999
		match_replace << {
			:match => "(#{r[:circa]})?[0-1]?[0-9]/[0-3]?[0-9]/#{r[:year]}",
			:proc => proc_date_with_slashes,
			:id => 350
		}

		# 19th century
		match_replace << {
			:match => "(#{r[:decade_qualifier]})?\s?[0-2]?[0-9]\s[Cc][Ee][Nn][Tt][Uu][Rr][Yy]",
			:proc => proc_century_with_qualifiers,
			:id => 360
		}

		match_replace
	end


	def self.proc_single_year
		proc = Proc.new do |string, open_range|
			year = string.gsub(/[^0-9]*/,'')
			@dates[:index_dates] << year.to_i
			case open_range
			when 'start'
				@dates[:date_start] = year
			when 'end'
				@dates[:date_end] = year
			else
				@dates[:date_start] = year
				@dates[:date_end] = year
			end
		end
	end


	# 1999
	def self.proc_year_range
		proc = Proc.new do |string|
			# Only supports years from 1000
			range = year_range(string)
			if range.length > 0
				range_start, range_end = range
				if range_end > range_start

					(range_start..range_end).to_a.each { |d| @dates[:index_dates] << d }

					@dates[:inclusive_range] = true
					process_year_range()
				end
			end
		end
	end

	# 1999 - 2010s
	def self.proc_range_year_to_decade
		proc = Proc.new do |string|
				range = year_range(string)
				range_start, range_end_decade = range

			if range_start && range_end_decade
				if range_end_decade > range_start
					range_end = range_end_decade + 9
					(range_start..range_end).to_a.each { |d| @dates[:index_dates] << d }
					@dates[:inclusive_range] = true
					process_year_range()
				end
			end
		end
	end


	# 1990-91
	def self.proc_year_range_short
		proc = Proc.new do |string|
			range = string.split('-')
			range.each { |d| d.gsub!(/[^0-9]*/,'') }
			decade_string = range[0].match(/^[0-9]{2}/).to_s
			range[1] = decade_string + range[1]
			range_start = range[0].to_i
			range_end = range[1].to_i

			if range_end > range_start
				(range_start..range_end).to_a.each { |d| @dates[:index_dates] << d }
				@dates[:inclusive_range] = true
				process_year_range()
			end
		end
	end

	# this may be obsolete - however, keep it just in case
	def self.proc_year_range_list_combo
		proc = Proc.new do |string|
			ranges = []
			list = []
			index_dates = []
			years = string.scan(/[0-2][0-9]{3}/)
			delimiters = string.scan(/\s?[\-\;\,]\s?/)
			delimiters.each { |d| d.strip! }
			i = 0
			while i < years.length
				y1 = years[i]
				d = delimiters[i]
				if d == '-'
					y2 = years[i + 1]
					ranges << [y1,y2]
					i += 2
				else
					list << y1
					i += 1
				end
			end
			ranges.each do |r|
				range_start = r[0].to_i
				range_end = r[1].to_i
				(range_start..range_end).to_a.each { |d| index_dates << d }
			end
			list.each { |y| index_dates << y.to_i }
			index_dates.sort!
			@dates[:index_dates] = index_dates
			@dates[:inclusive_range] = false
			process_year_range()
		end
	end

	# 1990s
	def self.proc_decade_s
		proc = Proc.new do |string|
			decade = string.match(/[0-9]{3}0/).to_s
			decade_start = decade.to_i
			decade_end = (decade_start + 9)
			@dates[:index_dates] = (decade_start..decade_end).to_a
			@dates[:inclusive_range] = true
			process_year_range()
		end
	end

	# 19--
	def self.proc_century_with_placeholders
		proc = Proc.new do |string|
			century = string.match(/[0-9]{2}/).to_s
			century += '00'
			century_start = century.to_i
			century_end = (century_start + 99)
			@dates[:index_dates] = (century_start..century_end).to_a
			@dates[:inclusive_range] = true
			process_year_range()
		end
	end

	# mid 19th century
	def self.proc_century_with_qualifiers
		proc = Proc.new do |string|
			century = string.match(/[0-9]{2}/).to_s

			if string.match(/[Ee]arly/)
				range_start = '00'
				range_end = '40'
			elsif string.match(/[Mm]id(dle)?/)
				range_start = '30'
				range_end = '80'
			elsif string.match(/[Ll]ate/)
				range_start = '70'
				range_end = '00'
			else
				range_start = '00'
				range_end = '99'
			end

			century_start = (century + range_start).to_i - 100
			century_end = (century + range_end).to_i - 100

			@dates[:index_dates] = (century_start..century_end).to_a
			@dates[:inclusive_range] = true
			process_year_range()
		end
	end

	# early 1990s
	def self.proc_decade_s_qualified
		proc = Proc.new do |string|
			decade = string.match(/[0-9]{3}0/).to_s
			decade_start = decade.to_i
			if string.match(/[Ee]arly/)
				range_start = decade_start
				range_end = decade_start + 5
			elsif string.match(/[Mm]id(dle)?/)
				range_start = decade_start + 3
				range_end = range_start + 5
			elsif string.match(/[Ll]ate/)
				range_start = decade_start + 5
				range_end = decade_start + 9
			end
			@dates[:index_dates] = (range_start..range_end).to_a
			@dates[:inclusive_range] = true
			process_year_range()
		end
	end

	# 1990s-2000s
	def self.proc_decade_s_range
		proc = Proc.new do |string|
			decades = string.scan(/[0-9]{3}0/)
			if decades.length == 2
				range_start = decades[0].to_i
				range_end = decades[1].to_i + 9
				@dates[:index_dates] = (range_start..range_end).to_a
				@dates[:inclusive_range] = true
				process_year_range()
			end
		end
	end

	# 1999-09-09
	# September 9, 1999
	# 1999 September 9
	def self.proc_full_date_single
		proc = Proc.new do |string|
			datetime = full_date_single_to_datetime(string)
			if datetime
				@dates[:date_start] = datetime.strftime('%Y-%m-%d')
				@dates[:index_dates] << datetime.strftime('%Y').to_i
			end
		end
	end

	# September 1999
	# 1999 September
	def self.proc_month_year_single
		proc = Proc.new do |string|
			string.gsub!(/\?/,'')

			datetime = DateTime.parse(string)
			if datetime
				@dates[:date_start] = datetime.strftime('%Y-%m')
				@dates[:index_dates] << datetime.strftime('%Y').to_i
			end
		end
	end

	# "1976 July 4 - 1981 October 1", etc.
	# call with second argument 'month' if no day value is present
	def self.proc_full_date_single_range
		proc = Proc.new do |string, specificity|
			dates = []
			full_date_format = (specificity == 'month') ? '%Y-%m' : '%Y-%m-%d'
			if string.match(/\-/)
				dates = string.split('-')
			elsif string.match(/\sto\s/)
				dates = string.split(' to ')
			end

			dates.each { |d| d.strip! }

			if dates.length == 2
				datetime_start = full_date_single_to_datetime(dates[0])
				datetime_end = full_date_single_to_datetime(dates[1])

				# if month-specific, modify datetimes to include all days of each month
				if specificity == 'month'
					month_date_start = datetime_start.strftime('%Y-%m')
					datetime_start = DateTime.parse(month_date_start + '-01')
					month_date_end = datetime_end.strftime('%Y-%m')
					month_date_end_parts = month_date_end.split('-')

					month_date_end_last = Utilities.days_in_month(month_date_end_parts[1],month_date_end_parts[0]).to_s
					month_date_full = month_date_end + "-#{month_date_end_last}"

					datetime_end = DateTime.parse(month_date_full)
				end

				if datetime_start && datetime_end
					process_date_range(datetime_start,datetime_end,specificity)
				end
				@dates[:inclusive_range] = true
			end
		end
	end


	# Feb. 1-20, 1980
	# 1980 Feb. 1-20
	# 1980 1-20 Feb.
	def self.proc_single_month_date_range
		proc = Proc.new do |string|
			year = Utilities.extract_year(string)
			day_range = string.match(/\d{1,2}\-\d{1,2}/).to_s
			string.gsub!(Regexp.new(day_range),'')
			month = string.strip
			days = day_range.split('-')
			dates = []
			if days.length == 2
				days.each do |d|
					d.strip!
					dates << "#{month} #{d} #{year}"
				end
				datetime_start = full_date_single_to_datetime(dates[0])
				datetime_end = full_date_single_to_datetime(dates[1])
				if datetime_start && datetime_end
					process_date_range(datetime_start,datetime_end)
				end
			end
			@dates[:inclusive_range] = true
		end
	end


	def self.proc_8601_range
		proc = Proc.new do |string|
			dates = string.split('/')
			dates.each { |d| d.strip! }

			datetime_start = iso8601_datetime(dates[0])
			datetime_end = iso8601_datetime(dates[1])

			if datetime_start && datetime_end
				year_start = datetime_start.strftime('%Y').to_i
				year_end = datetime_end.strftime('%Y').to_i

				if Utilities.datetime_comparitor(datetime_end) < Utilities.datetime_comparitor(datetime_start)
					# this range is reversed in error
					years = [year_end,year_start]
					year_start, year_end = years[0], years[1]
					datetimes = [datetime_end,datetime_start]
					datetime_start, datetime_end = datetimes[0], datetimes[1]
				end

				@dates[:index_dates] += (year_start..year_end).to_a
				@dates[:date_start] = datetime_start.strftime(iso8601_string_format dates[0])
				@dates[:date_end] = datetime_end.strftime(iso8601_string_format dates[1])
				@dates[:inclusive_range] = true

			end
		end
	end


	# "1981 Oct-Dec", "Oct-Dec 1981", etc.
	def self.proc_single_year_month_range
		proc = Proc.new do |string|
			year = string.match(/[0-9]{4}/).to_s
			string.gsub!(year,'')
			string.strip!
			first_month = string.match(@regex_tokens[:named_month]).to_s
			last_month = string.match(@regex_tokens[:named_month] + '$').to_s

			date_string_first = first_month + ' 1,' + year
			datetime_first = DateTime.parse(date_string_first)
			if !last_month.empty?
				@dates[:date_start] = datetime_first.strftime('%Y-%m')
				date_string_last = last_month + ' ' + year
				datetime_last = DateTime.parse(date_string_last)
				@dates[:date_end] = datetime_last.strftime('%Y-%m')
			end
			@dates[:inclusive_range] = true
			@dates[:index_dates] << year.to_i
		end
	end


	# 1942 November-1943
	# 1943-1944 November
	# November 1942-1943
	# 1942-November 1943
	def self.proc_year_range_single_date
		proc = Proc.new do |string|
			dates = []
			if string.match(/\-/)
				dates = string.split('-')
			elsif string.match(/\sto\s/)
				dates = string.split(' to ')
			end

			dates.each { |d| d.strip! }
			if dates.length == 2
				if dates[0].match(/[A-Za-z]/)
					datetime_start = full_date_single_to_datetime(dates[0] + "-01")
					datetime_end = full_date_single_to_datetime(dates[1] + "-12-31")
				else
					datetime_start = full_date_single_to_datetime(dates[0] + "-01-01")
					datetime_end_tmp = full_date_single_to_datetime(dates[1] + "-28")
					datetime_end = full_date_single_to_datetime(dates[1] + "-" + Utilities.days_in_month(datetime_end_tmp.month, datetime_end_tmp.year).to_s)
				end

				if datetime_start && datetime_end
					process_date_range(datetime_start,datetime_end,"month")
				end
				@dates[:inclusive_range] = true

			end
		end
	end

	# Jan 2-Dec 31 1865
	# 1865 Jan 2-Dec 31
	def self.proc_year_with_dates
		proc = Proc.new do |string|
			# extract year for later
			year = string.match(/[0-9]{4}/).to_s

			# instead of dealing with punctuation, we'll scorch the earth
			string.gsub!(/[\,\?]/,'')

			# split the string into two different dates
			if string.match(/\-/)
				dates = string.split('-')
			elsif string.match(/\sto\s/)
				dates = string.split(' to ')
			end

			# if everything's as expected, append the year to the shorter date
			if dates.length == 2
				dates.each { |d|
					if d.match(year).nil?
						d << " "
						d << year
					end
				}

				# change our strings to datetime objects
				# and send them to be processed elsewhere
				datetime_start = DateTime.parse(dates[0])
				datetime_end = DateTime.parse(dates[1])
				process_date_range(datetime_start, datetime_end)
				@dates[:inclusive_range] = true
			end
		end
	end

	# 1863 Aug 7-1866 Dec
	def self.proc_full_with_year_month
		proc = Proc.new do |string|
			dates = []
			if string.match(/\-/)
				dates = string.split('-')
			elsif string.match(/\sto\s/)
				dates = string.split(' to ')
			end

			dates.each { |d| d.strip! }

			if dates.length == 2

				datetime_end = full_date_single_to_datetime(dates[1])

				if !dates[0].match(/[0-9]\D+[0-9]/).nil?
					datetime_start = full_date_single_to_datetime(dates[0])
					month_date_start = datetime_start.strftime('%Y-%m-%d')
					month_date_end = datetime_end.strftime('%Y-%m')
					month_date_end_parts = month_date_end.split('-')

					month_date_end_last = Utilities.days_in_month(month_date_end_parts[1],month_date_end_parts[0]).to_s
					month_date_full = month_date_end + "-#{month_date_end_last}"

					datetime_end = DateTime.parse(month_date_full)
				else
					datetime_start = full_date_single_to_datetime(dates[0] + "-01")
					if datetime_start && datetime_end
						month_date_start = datetime_start.strftime('%Y-%m')
						month_date_end = datetime_end.strftime('%Y-%m-%d')
					end
				end

				if datetime_start && datetime_end
					process_date_range(datetime_start,datetime_end)
				end
				@dates[:inclusive_range] = true
			end
		end
	end

	# we assume that all matching dates are mm/dd/yyyy
	# if they're dd/mm/yyyy, this may get jumbled, but that's rare enough to be okay
	def self.proc_date_with_slashes
		proc = Proc.new do |string|
			dates = string.split('/')
			dates.collect! do |d|
				d.strip!
				if d.length == 1
					# convert to ISO style numbers
					d = "0" + d.to_s
				else
					# i am not proud of this
					d = d
				end
			end
			proc_full_date_single.call(dates[2].to_s + "-" + dates[0].to_s + "-" + dates[1].to_s)
		end
	end

	# Transform full date strings into parsed datetime objects
	# e.g. "September 9, 1999" -> datetime
	def self.full_date_single_to_datetime(string)
		new_string = string.clone
		if new_string.match(/\d{4}\-\d{2}\-\d{2}/)
			parse_string = new_string
		else
			year = new_string.match(/[0-9]{4}/).to_s
			new_string.gsub!(Regexp.new(year), '')
			if new_string.match(/[0-9]{1,2}/)
				day = new_string.match(/[0-9]{1,2}/).to_s
				new_string.gsub!(Regexp.new(day), '')
			else
				day = nil
			end

			new_string.gsub!(/[\.\,\s\-]+/,'')

			month = new_string.clone
			parse_string = month
			parse_string += day ? " #{day}, #{year}" : " #{year}"
		end
		datetime = DateTime.parse(parse_string)
	end


	def self.process_date_range(datetime_start,datetime_end,specificity=nil)

		if !datetime_start || !datetime_end
			return
		end

		date_format = (specificity == 'month') ? '%Y-%m' : '%Y-%m-%d'

		year_start = datetime_start.strftime('%Y').to_i
		year_end = datetime_end.strftime('%Y').to_i

		if Utilities.datetime_comparitor(datetime_end) > Utilities.datetime_comparitor(datetime_start)

			@dates[:index_dates] += (year_start..year_end).to_a

			@dates[:date_start] = datetime_start.strftime(date_format)
			@dates[:date_end] = datetime_end.strftime(date_format)

			@dates[:date_start_full] = datetime_start.strftime('%Y-%m-%d')
			@dates[:date_end_full] = datetime_end.strftime('%Y-%m-%d')
		end
	end

	# generates date_start and date_end from index_dates list
	def self.process_year_range
		@dates[:index_dates].sort!
		@dates[:index_dates].uniq!
		@dates[:date_start] = @dates[:index_dates].first
		@dates[:date_end] = @dates[:index_dates].last
	end


	# detects format of ISO8601 date to pass to strftime
	def self.iso8601_string_format(iso_8601_date)
		if iso_8601_date.match(/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$/)
			return '%Y-%m-%d'
		elsif iso_8601_date.match(/^[0-9]{4}\-[0-9]{2}$/)
			return '%Y-%m'
		else
			return '%Y'
		end
	end

	# generates datetime from ISO8601-formatted date
	def self.iso8601_datetime(iso_8601_date)
		if iso_8601_date.match(/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$/)
			DateTime.parse(iso_8601_date)
		elsif iso_8601_date.match(/^[0-9]{4}\-[0-9]{2}$/)
			DateTime.parse(iso_8601_date + '-01')
		else
			DateTime.parse(iso_8601_date + '-01-01')
		end
	end

	def self.year_range(string)
		range = string.scan(Regexp.new(@regex_tokens[:year]))
		range.each { |d| d.gsub!(/[^0-9]*/,'') }
		range.map { |y| y.to_i }
	end

	# enrich the final output hash with more comprehensive date metadata
	def self.add_full_dates
		if @dates[:date_start] && !@dates[:date_start_full]
			if @dates[:date_start].match(/\d{4}\-\d{2}\-\d{2}/)
				@dates[:date_start_full] = @dates[:date_start]
			elsif @dates[:date_start].match(/\d{4}\-\d{2}/)
				@dates[:date_start_full] = @dates[:date_start] + "-01"
			elsif @dates[:date_start].match(/\d{4}/)
				@dates[:date_start_full] = @dates[:date_start] + "-01-01"
			end
		end
		if @dates[:date_end] && !@dates[:date_end_full]
			if @dates[:date_end].match(/\d{4}\-\d{2}\-\d{2}/)
				@dates[:date_end_full] = @dates[:date_end]
			else
				year = @dates[:date_end].match(/^\d{4}/).to_s
				if @dates[:date_end].match(/\d{4}\-\d{2}/)
					month = @dates[:date_end].match(/\d{2}$/).to_s
					day = Utilities.days_in_month(month,year).to_s
					@dates[:date_end_full] = @dates[:date_end] + "-#{day}"
				elsif @dates[:date_end].match(/\d{4}/)
					@dates[:date_end_full] = @dates[:date_end] + "-12-31"
				end
			end
		end
	end
end
