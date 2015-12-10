require 'chronic'

class Parser

	def self.string_to_dates(str, hash, options)
		@string = str
		@dates = hash
		@options = options

		@regex_tokens = regex_tokens

		# perform this here, before the string gets purged of certainty indicators
		@dates[:certainty] = return_certainty(@string)

		@string = clean_string(@string)
		self.match_replace

		# if there are any future dates, return an empty hash
		if @dates[:index_dates] != [] && @dates[:index_dates].last > Time.now.year
			return { :original_string => @string, :index_dates => [], :keydate => nil, :keydate_z => nil, :date_start => nil, :date_end => nil,
				:date_start_full => nil, :date_end_full => nil, :inclusive_range => nil, :certainty => nil }
		end

		if @dates[:date_start] && !@dates[:date_end] && !(@dates[:test_data] == 150 || @dates[:test_data] == 160)
			@dates[:date_end] = @dates[:date_start]
		end

		stringify_values
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


	def self.proc_full_date_single
		proc = Proc.new do |string|
			datetime = full_date_single_to_datetime(string)
			if datetime
				full_date_single_keydates(string,datetime,'%Y-%m-%d')
				@dates[:index_dates] << datetime.strftime('%Y').to_i
			end
		end
	end


	def self.proc_month_year_single
		proc = Proc.new do |string|
			string.gsub!(/\?/,'')

			# Chronic can't parse year-month strings properly
			# so we need to change them to month-year before
			# parsing them.

			if string.match(/^[0-9]/)
				tmpyear = string.split(' ')[0]
				string.gsub!(/^.+? /,'')
				string << " "
				string << tmpyear
			end

			datetime = Chronic.parse(string)
			if datetime
				full_date_single_keydates(string,datetime, '%Y-%m')
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
					datetime_start = Chronic.parse(month_date_start + '-01')
					month_date_end = datetime_end.strftime('%Y-%m')
					month_date_end_parts = month_date_end.split('-')

					month_date_end_last = days_in_month(month_date_end_parts[1],month_date_end_parts[0]).to_s
					month_date_full = month_date_end + "-#{month_date_end_last}"

					datetime_end = Chronic.parse(month_date_full)
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
			year = extract_year(string)
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

				if datetime_comparitor(datetime_end) < datetime_comparitor(datetime_start)
					# this range is reversed in error
					years = [year_end,year_start]
					year_start, year_end = years[0], years[1]
					datetimes = [datetime_end,datetime_start]
					datetime_start, datetime_end = datetimes[0], datetimes[1]
				end

				@dates[:index_dates] += (year_start..year_end).to_a
				@dates[:date_start] = datetime_start.strftime(is8601_string_format dates[0])
				@dates[:date_end] = datetime_end.strftime(is8601_string_format dates[1])
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

	# chronic is fiddly about short months with periods
	# (e.g. "may.") so we remove them
			date_string_first = first_month.delete('.') + ' 1,' + year
			datetime_first = Chronic.parse(date_string_first)
			if !last_month.empty?
				@dates[:date_start] = datetime_first.strftime('%Y-%m')
				date_string_last = last_month + ' ' + year
				datetime_last = Chronic.parse(date_string_last)
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
					datetime_end = full_date_single_to_datetime(dates[1] + "-" + days_in_month(datetime_end_tmp.month, datetime_end_tmp.year).to_s)
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

					# Chronic seemed to choke with YYYY-MM-DD dates
					# so we'll flip it to MM-DD-YYYY
					if d.match("^" + year)
						d.gsub!(year + " ","")
						d << " "
						d << year
					end
				}

				# change our strings to datetime objects
				# and send them to be processed elsewhere
				datetime_start = Chronic.parse(dates[0])
				datetime_end = Chronic.parse(dates[1])
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

					month_date_end_last = days_in_month(month_date_end_parts[1],month_date_end_parts[0]).to_s
					month_date_full = month_date_end + "-#{month_date_end_last}"

					datetime_end = Chronic.parse(month_date_full)
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
			:decade_qualifier => '([Ee]arly)|([Mm]id)|([Ll]ate)\-?',
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

			new_string.gsub!(/[\.\,\s]+/,'')

			month = new_string.clone
			parse_string = month
			parse_string += day ? " #{day}, #{year}" : " #{year}"
		end
		datetime = Chronic.parse(parse_string)
	end


	def self.process_date_range(datetime_start,datetime_end,specificity=nil)

		if !datetime_start || !datetime_end
			return
		end

		date_format = (specificity == 'month') ? '%Y-%m' : '%Y-%m-%d'

		year_start = datetime_start.strftime('%Y').to_i
		year_end = datetime_end.strftime('%Y').to_i

		if datetime_comparitor(datetime_end) > datetime_comparitor(datetime_start)

			@dates[:index_dates] += (year_start..year_end).to_a

			@dates[:date_start] = datetime_start.strftime(date_format)
			@dates[:date_end] = datetime_end.strftime(date_format)

			@dates[:date_start_full] = datetime_start.strftime('%Y-%m-%d')
			@dates[:date_end_full] = datetime_end.strftime('%Y-%m-%d')
		end
	end


	def self.full_date_single_keydates(string,datetime,format)
		@dates[:date_start] = datetime.strftime(format)
	end


	def self.process_year_range
		@dates[:index_dates].sort!
		@dates[:index_dates].uniq!
		@dates[:date_start] = @dates[:index_dates].first
		@dates[:date_end] = @dates[:index_dates].last
	end


	def self.is8601_string_format(iso_8601_date)
		if iso_8601_date.match(/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$/)
			return '%Y-%m-%d'
		elsif iso_8601_date.match(/^[0-9]{4}\-[0-9]{2}$/)
			return '%Y-%m'
		else
			return '%Y'
		end
	end


	def self.iso8601_datetime(iso_8601_date)
		if iso_8601_date.match(/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$/)
			Chronic.parse(iso_8601_date)
		elsif iso_8601_date.match(/^[0-9]{4}\-[0-9]{2}$/)
			Chronic.parse(iso_8601_date + '-01')
		else
			Chronic.parse(iso_8601_date + '-01-01')
		end
	end


	# Removes the first 4-digit number found in the string and returns it
	def self.extract_year(string)
		year = string.match(/\d{4}/).to_s
		string.gsub!(Regexp.new(year),'')
		year
	end


	# removes sub-strings that do not contain parsable data
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
		string
	end

	def self.year_range(string)
		range = string.scan(Regexp.new(@regex_tokens[:year]))
		range.each { |d| d.gsub!(/[^0-9]*/,'') }
		range.map { |y| y.to_i }
	end


	def self.datetime_comparitor(datetime)
		d = datetime.to_s
		d.gsub!(/[^\d]/,'')
		return d.to_i
	end


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


	# month and year must be numeric
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


	def self.stringify_values
		@dates.each do |k,v|
			if v.is_a?(Fixnum)
				@dates[k] = v.to_s
			end
		end
	end


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
					day = days_in_month(month,year).to_s
					@dates[:date_end_full] = @dates[:date_end] + "-#{day}"
				elsif @dates[:date_end].match(/\d{4}/)
					@dates[:date_end_full] = @dates[:date_end] + "-12-31"
				end
			end
		end
	end

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
end
