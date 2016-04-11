# encoding: utf-8

require 'spec_helper'
require 'timetwister'

describe Timetwister do

	it "parses ISO 8601 single dates" do
		date = Timetwister.parse("1776-07-04")
		expect(date[0][:date_start]).to eq(date[0][:date_end])
		expect(date[0][:test_data]).to eq("30")
	end

	it "parses ISO 8601 date ranges" do
		forms = ["1776-07-04/1789-03-01", "1789-03-01/1776-07-04"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq("1776-07-04")
			expect(date[0][:date_end]).to eq("1789-03-01")
			expect(date[0][:inclusive_range]).to eq(true)
			expect(date[0][:test_data]).to eq("40")
		end
	end

	it "parses definite and approximate single years" do
		date = Timetwister.parse("1776")
		expect(date[0][:date_start]).to eq("1776")
		expect(date[0][:date_end]).to eq("1776")
		expect(date[0][:date_start_full]).to eq("1776-01-01")
		expect(date[0][:date_end_full]).to eq("1776-12-31")
		expect(date[0][:test_data]).to eq("70")

		date = Timetwister.parse("ca. 1776")
		expect(date[0][:date_start]).to eq("1776")
		expect(date[0][:date_end]).to eq("1776")
		expect(date[0][:date_start_full]).to eq("1776-01-01")
		expect(date[0][:date_end_full]).to eq("1776-12-31")
		expect(date[0][:test_data]).to eq("70")

		date = Timetwister.parse("[1776]")
		expect(date[0][:date_start]).to eq("1776")
		expect(date[0][:date_end]).to eq("1776")
		expect(date[0][:date_start_full]).to eq("1776-01-01")
		expect(date[0][:date_end_full]).to eq("1776-12-31")
		expect(date[0][:test_data]).to eq("70")
	end

	it "parses ranges of full dates" do

		forms = ["July 4 1776 - March 1 1789", "4 July 1776 - 1 March 1789", "1776 July 4 - 1789 March 1", "1776 4 July - 1789 1 March", "1776 4 July to 1789 1 March"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq("1776-07-04")
			expect(date[0][:date_start_full]).to eq("1776-07-04")
			expect(date[0][:date_end]).to eq("1789-03-01")
			expect(date[0][:date_end_full]).to eq("1789-03-01")
			expect(date[0][:inclusive_range]).to eq(true)
			expect(date[0][:index_dates]).to eq([1776, 1777, 1778, 1779, 1780, 1781, 1782, 1783, 1784, 1785, 1786, 1787, 1788, 1789])
			expect(date[0][:test_data]).to eq("80")
		end
	end

	it "parses ranges of months+dates" do
		forms = ["July 1776 - March 1789", "1776 July - 1789 March"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq("1776-07")
			expect(date[0][:date_start_full]).to eq("1776-07-01")
			expect(date[0][:date_end]).to eq("1789-03")
			expect(date[0][:date_end_full]).to eq("1789-03-31")
			expect(date[0][:inclusive_range]).to eq(true)
			expect(date[0][:index_dates]).to eq([1776, 1777, 1778, 1779, 1780, 1781, 1782, 1783, 1784, 1785, 1786, 1787, 1788, 1789])
			expect(date[0][:test_data]).to eq("100")
		end
	end

	it "parses ranges of just years" do
		date = Timetwister.parse("1776 - 1789")
		expect(date[0][:date_start]).to eq("1776")
		expect(date[0][:date_start_full]).to eq("1776-01-01")
		expect(date[0][:date_end]).to eq("1789")
		expect(date[0][:date_end_full]).to eq("1789-12-31")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:index_dates]).to eq([1776, 1777, 1778, 1779, 1780, 1781, 1782, 1783, 1784, 1785, 1786, 1787, 1788, 1789])
		expect(date[0][:test_data]).to eq("120")
	end

	it "parses ranges of decades" do
		date = Timetwister.parse("1770's - 1780s")
		expect(date[0][:date_start]).to eq("1770")
		expect(date[0][:date_start_full]).to eq("1770-01-01")
		expect(date[0][:date_end]).to eq("1789")
		expect(date[0][:date_end_full]).to eq("1789-12-31")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:index_dates]).to eq([1770, 1771, 1772, 1773, 1774, 1775, 1776, 1777, 1778, 1779, 1780, 1781, 1782, 1783, 1784, 1785, 1786, 1787, 1788, 1789])
		expect(date[0][:test_data]).to eq("190")
	end

	it "parses ranges of a year and a decade" do
		date = Timetwister.parse("1770's - 1787")
		expect(date[0][:date_start]).to eq("1770")
		expect(date[0][:date_start_full]).to eq("1770-01-01")
		expect(date[0][:date_end]).to eq("1787")
		expect(date[0][:date_end_full]).to eq("1787-12-31")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:index_dates]).to eq([1770, 1771, 1772, 1773, 1774, 1775, 1776, 1777, 1778, 1779, 1780, 1781, 1782, 1783, 1784, 1785, 1786, 1787])
		expect(date[0][:test_data]).to eq("140")

		date = Timetwister.parse("1776 - 1780's")
		expect(date[0][:date_start]).to eq("1776")
		expect(date[0][:date_start_full]).to eq("1776-01-01")
		expect(date[0][:date_end]).to eq("1789")
		expect(date[0][:date_end_full]).to eq("1789-12-31")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:index_dates]).to eq([1776, 1777, 1778, 1779, 1780, 1781, 1782, 1783, 1784, 1785, 1786, 1787, 1788, 1789])
		expect(date[0][:test_data]).to eq("130")
	end

	it "parses ranges of a year and a two-digit year" do
		date = Timetwister.parse("1771 - 76")
		expect(date[0][:date_start]).to eq("1771")
		expect(date[0][:date_start_full]).to eq("1771-01-01")
		expect(date[0][:date_end]).to eq("1776")
		expect(date[0][:date_end_full]).to eq("1776-12-31")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:index_dates]).to eq([1771, 1772, 1773, 1774, 1775, 1776])
		expect(date[0][:test_data]).to eq("145")
	end

	it "parses open-ended ranges" do
		date = Timetwister.parse("1776 - ")
		expect(date[0][:date_start]).to eq("1776")
		expect(date[0][:date_start_full]).to eq("1776-01-01")
		expect(date[0][:date_end]).to eq(nil)
		expect(date[0][:index_dates]).to eq([1776])
		expect(date[0][:test_data]).to eq("150")

		date = Timetwister.parse(" - 1776")
		expect(date[0][:date_end]).to eq("1776")
		expect(date[0][:date_end_full]).to eq("1776-12-31")
		expect(date[0][:date_start]).to eq(nil)
		expect(date[0][:index_dates]).to eq([1776])
		expect(date[0][:test_data]).to eq("160")
	end

	it "parses undated values" do
		forms = ["n.d.", "undated", "no date"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq(nil)
			expect(date[0][:date_start_full]).to eq(nil)
			expect(date[0][:date_end]).to eq(nil)
			expect(date[0][:date_end_full]).to eq(nil)
			expect(date[0][:inclusive_range]).to eq(nil)
			expect(date[0][:index_dates]).to eq([])
			expect(date[0][:test_data]).to eq(nil)
		end
	end

	it "parses single decades" do
		date = Timetwister.parse("1770's")
		expect(date[0][:date_start]).to eq("1770")
		expect(date[0][:date_start_full]).to eq("1770-01-01")
		expect(date[0][:date_end]).to eq("1779")
		expect(date[0][:date_end_full]).to eq("1779-12-31")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:index_dates]).to eq([1770, 1771, 1772, 1773, 1774, 1775, 1776, 1777, 1778, 1779])
		expect(date[0][:test_data]).to eq("180")
	end

	it "parses single full dates" do
		forms = ["July 4 1776", "4 July 1776", "1776 July 4", "1776 4 July"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq("1776-07-04")
			expect(date[0][:date_start_full]).to eq("1776-07-04")
			expect(date[0][:date_end]).to eq("1776-07-04")
			expect(date[0][:date_end_full]).to eq("1776-07-04")
			expect(date[0][:index_dates]).to eq([1776])
			expect(date[0][:test_data]).to eq("200")
		end
	end

	it "parses single month+year" do
		forms = ["December 1776", "1776 December", "Dec 1776", "1776 Dec"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq("1776-12")
			expect(date[0][:date_start_full]).to eq("1776-12-01")
			expect(date[0][:date_end]).to eq("1776-12")
			expect(date[0][:date_end_full]).to eq("1776-12-31")
			expect(date[0][:index_dates]).to eq([1776])
			expect(date[0][:test_data]).to eq("220")
		end
	end

	it "parses month ranges within one year" do
		forms = ["July-September 1776", "1776 July-September"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq("1776-07")
			expect(date[0][:date_start_full]).to eq("1776-07-01")
			expect(date[0][:date_end]).to eq("1776-09")
			expect(date[0][:date_end_full]).to eq("1776-09-30")
			expect(date[0][:index_dates]).to eq([1776])
			expect(date[0][:inclusive_range]).to eq(true)
			expect(date[0][:test_data]).to eq("230")
		end
	end

	it "parses a day range within a single month+year" do
		forms = ["4-10 July 1776", "1776 July 4-10", "July 4-10, 1776", "1776 4-10 July"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq("1776-07-04")
			expect(date[0][:date_start_full]).to eq("1776-07-04")
			expect(date[0][:date_end]).to eq("1776-07-10")
			expect(date[0][:date_end_full]).to eq("1776-07-10")
			expect(date[0][:index_dates]).to eq([1776])
			expect(date[0][:test_data]).to eq("240")
			expect(date[0][:inclusive_range]).to eq(true)
		end
	end

	it "parses decades with early/mid/late qualifiers" do
		date = Timetwister.parse("early 1770's")
		expect(date[0][:date_start]).to eq("1770")
		expect(date[0][:date_start_full]).to eq("1770-01-01")
		expect(date[0][:date_end]).to eq("1775")
		expect(date[0][:date_end_full]).to eq("1775-12-31")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:index_dates]).to eq([1770, 1771, 1772, 1773, 1774, 1775])
		expect(date[0][:test_data]).to eq("250")

		date = Timetwister.parse("mid 1770's")
		expect(date[0][:date_start]).to eq("1773")
		expect(date[0][:date_start_full]).to eq("1773-01-01")
		expect(date[0][:date_end]).to eq("1778")
		expect(date[0][:date_end_full]).to eq("1778-12-31")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:index_dates]).to eq([1773, 1774, 1775, 1776, 1777, 1778])
		expect(date[0][:test_data]).to eq("250")

		date = Timetwister.parse("late 1770's")
		expect(date[0][:date_start]).to eq("1775")
		expect(date[0][:date_start_full]).to eq("1775-01-01")
		expect(date[0][:date_end]).to eq("1779")
		expect(date[0][:date_end_full]).to eq("1779-12-31")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:index_dates]).to eq([1775, 1776, 1777, 1778, 1779])
		expect(date[0][:test_data]).to eq("250")
	end

	it "parses ambiguous dates (e.g. 18--)" do
		date = Timetwister.parse("17--")
		expect(date[0][:date_start]).to eq("1700")
		expect(date[0][:date_start_full]).to eq("1700-01-01")
		expect(date[0][:date_end]).to eq("1799")
		expect(date[0][:date_end_full]).to eq("1799-12-31")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:index_dates][0]).to eq(1700)
		expect(date[0][:index_dates][99]).to eq(1799)
		expect(date[0][:test_data]).to eq("290")
	end

	it "parses day/month ranges within a single year" do
		forms = ["4 May - 10 July 1776", "1776 May 4 - July 10", "May 4 - July 10 1776", "4 May - 10 July 1776", "4 May to 10 July 1776"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq("1776-05-04")
			expect(date[0][:date_start_full]).to eq("1776-05-04")
			expect(date[0][:date_end]).to eq("1776-07-10")
			expect(date[0][:date_end_full]).to eq("1776-07-10")
			expect(date[0][:index_dates]).to eq([1776])
			expect(date[0][:test_data]).to eq("310")
			expect(date[0][:inclusive_range]).to eq(true)
		end
	end

	it "parses full date + year/month date range" do
		forms = ["4 July 1776 - March 1789", "1776 July 4 - 1789 March", "1776 July 4 to 1789 March"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq("1776-07-04")
			expect(date[0][:date_start_full]).to eq("1776-07-04")
			expect(date[0][:date_end]).to eq("1789-03-31")
			expect(date[0][:date_end_full]).to eq("1789-03-31")
			expect(date[0][:index_dates]).to eq([1776, 1777, 1778, 1779, 1780, 1781, 1782, 1783, 1784, 1785, 1786, 1787, 1788, 1789])
			expect(date[0][:test_data]).to eq("330")
			expect(date[0][:inclusive_range]).to eq(true)
		end

		forms = ["July 1776 - March 1, 1789", "1776 July - 1789 March 1"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq("1776-07-01")
			expect(date[0][:date_start_full]).to eq("1776-07-01")
			expect(date[0][:date_end]).to eq("1789-03-01")
			expect(date[0][:date_end_full]).to eq("1789-03-01")
			expect(date[0][:index_dates]).to eq([1776, 1777, 1778, 1779, 1780, 1781, 1782, 1783, 1784, 1785, 1786, 1787, 1788, 1789])
			expect(date[0][:test_data]).to eq("330")
			expect(date[0][:inclusive_range]).to eq(true)
		end
	end

	# the normalized dates returned here are a bit funny
	# we could do with standardizing them
	it "parses year + month/year range" do
		forms = ["1776 - March 1789", "1776 - 1789 March", "1776 to 1789 March"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq("1776-01")
			expect(date[0][:date_start_full]).to eq("1776-01-01")
			expect(date[0][:date_end]).to eq("1789-03")
			expect(date[0][:date_end_full]).to eq("1789-03-31")
			expect(date[0][:index_dates]).to eq([1776, 1777, 1778, 1779, 1780, 1781, 1782, 1783, 1784, 1785, 1786, 1787, 1788, 1789])
			expect(date[0][:test_data]).to eq("340")
			expect(date[0][:inclusive_range]).to eq(true)
		end

		forms = ["1776 July - 1789", "July 1776 - 1789"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq("1776-07")
			expect(date[0][:date_start_full]).to eq("1776-07-01")
			expect(date[0][:date_end]).to eq("1789-12")
			expect(date[0][:date_end_full]).to eq("1789-12-31")
			expect(date[0][:index_dates]).to eq([1776, 1777, 1778, 1779, 1780, 1781, 1782, 1783, 1784, 1785, 1786, 1787, 1788, 1789])
			expect(date[0][:test_data]).to eq("340")
			expect(date[0][:inclusive_range]).to eq(true)
		end
	end

	it "parses mm/dd/yyyy dates" do
		forms = ["7/4/1776", "07/4/1776", "7/04/1776", "07/04/1776"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq("1776-07-04")
			expect(date[0][:date_start_full]).to eq("1776-07-04")
			expect(date[0][:date_end]).to eq("1776-07-04")
			expect(date[0][:date_end_full]).to eq("1776-07-04")
			expect(date[0][:index_dates]).to eq([1776])
			expect(date[0][:test_data]).to eq("350")
		end
	end

	it "parses seasons" do
		date = Timetwister.parse("Winter 1776")
		expect(date[0][:date_start]).to eq("1776-01-01")
		expect(date[0][:date_start_full]).to eq("1776-01-01")
		expect(date[0][:date_end]).to eq("1776-03-20")
		expect(date[0][:date_end_full]).to eq("1776-03-20")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:index_dates]).to eq([1776])
		expect(date[0][:test_data]).to eq("310")

		date = Timetwister.parse("1776 Spring")
		expect(date[0][:date_start]).to eq("1776-03-20")
		expect(date[0][:date_start_full]).to eq("1776-03-20")
		expect(date[0][:date_end]).to eq("1776-06-21")
		expect(date[0][:date_end_full]).to eq("1776-06-21")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:index_dates]).to eq([1776])
		expect(date[0][:test_data]).to eq("310")

		date = Timetwister.parse("1776 Summer")
		expect(date[0][:date_start]).to eq("1776-06-21")
		expect(date[0][:date_start_full]).to eq("1776-06-21")
		expect(date[0][:date_end]).to eq("1776-09-23")
		expect(date[0][:date_end_full]).to eq("1776-09-23")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:index_dates]).to eq([1776])
		expect(date[0][:test_data]).to eq("310")

		date = Timetwister.parse("Fall 1776")
		expect(date[0][:date_start]).to eq("1776-09-23")
		expect(date[0][:date_start_full]).to eq("1776-09-23")
		expect(date[0][:date_end]).to eq("1776-12-22")
		expect(date[0][:date_end_full]).to eq("1776-12-22")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:index_dates]).to eq([1776])
		expect(date[0][:test_data]).to eq("310")
	end

	it "parses dates with punctuation" do
		forms = ["July 4 1776?", "July 4 1776 [?]", "July 4? 1776", "?July 4 1776?", "[July] 4 1776?"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq("1776-07-04")
			expect(date[0][:date_start_full]).to eq("1776-07-04")
			expect(date[0][:date_end]).to eq("1776-07-04")
			expect(date[0][:date_end_full]).to eq("1776-07-04")
			expect(date[0][:index_dates]).to eq([1776])
			expect(date[0][:test_data]).to eq("200")
		end
	end

	it "parses circa dates" do
		multi = ["ca. 1776 - 1777", "1776 - circa 1777", "ca 1776-77", "circa 1776 - 1777"]
		multi.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq('1776')
			expect(date[0][:date_end]).to eq('1777')
			expect(date[0][:index_dates]).to eq([1776,1777])
		end

		single = ["ca. December 1776", "circa 1776 Dec", "ca 1776 December"]
		single.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq('1776-12')
			expect(date[0][:index_dates]).to eq([1776])
		end

		multi_months = ["ca. January 1776 - February 1777", "January 1776 - circa February 1777"]
		multi_months.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq('1776-01')
			expect(date[0][:date_end]).to eq('1777-02')
			expect(date[0][:index_dates]).to eq([1776,1777])
		end

		# weird date forms
		date = Timetwister.parse("ca. 1776-77")
		expect(date[0][:date_start]).to eq('1776')
		expect(date[0][:date_end]).to eq('1777')
		expect(date[0][:index_dates]).to eq([1776,1777])

		date = Timetwister.parse("ca. January - February 1776")
		expect(date[0][:date_start]).to eq('1776-01')
		expect(date[0][:date_end]).to eq('1776-02')
		expect(date[0][:index_dates]).to eq([1776])

		date = Timetwister.parse("ca. early 1770's")
		expect(date[0][:date_start]).to eq('1770')
		expect(date[0][:date_end]).to eq('1775')
		expect(date[0][:index_dates]).to eq([1770,1771,1772,1773,1774,1775])

		date = Timetwister.parse("ca. 01/01/1776")
		expect(date[0][:date_start]).to eq('1776-01-01')
		expect(date[0][:index_dates]).to eq([1776])
	end

	it "parses dates with certainty values" do
		date = Timetwister.parse("Approximately July 4, 1776")
		expect(date[0][:date_start]).to eq("1776-07-04")
		expect(date[0][:date_start_full]).to eq("1776-07-04")
		expect(date[0][:date_end]).to eq("1776-07-04")
		expect(date[0][:date_end_full]).to eq("1776-07-04")
		expect(date[0][:index_dates]).to eq([1776])
		expect(date[0][:test_data]).to eq("200")
		expect(date[0][:certainty]).to eq("approximate")

		date = Timetwister.parse("[July 4, 1776]")
		expect(date[0][:date_start]).to eq("1776-07-04")
		expect(date[0][:date_start_full]).to eq("1776-07-04")
		expect(date[0][:date_end]).to eq("1776-07-04")
		expect(date[0][:date_end_full]).to eq("1776-07-04")
		expect(date[0][:index_dates]).to eq([1776])
		expect(date[0][:test_data]).to eq("200")
		expect(date[0][:certainty]).to eq("inferred")

		date = Timetwister.parse("July 4?, 1776")
		expect(date[0][:date_start]).to eq("1776-07-04")
		expect(date[0][:date_start_full]).to eq("1776-07-04")
		expect(date[0][:date_end]).to eq("1776-07-04")
		expect(date[0][:date_end_full]).to eq("1776-07-04")
		expect(date[0][:index_dates]).to eq([1776])
		expect(date[0][:test_data]).to eq("200")
		expect(date[0][:certainty]).to eq("questionable")

		date = Timetwister.parse("1771 - 76?")
		expect(date[0][:date_start]).to eq("1771")
		expect(date[0][:date_start_full]).to eq("1771-01-01")
		expect(date[0][:date_end]).to eq("1776")
		expect(date[0][:date_end_full]).to eq("1776-12-31")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:index_dates]).to eq([1771, 1772, 1773, 1774, 1775, 1776])
		expect(date[0][:test_data]).to eq("145")
		expect(date[0][:certainty]).to eq("questionable")
	end

	it "DOES NOT parse dates without years" do
		forms = ["July 4", "June - July", "January 12 - July 4"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq(nil)
			expect(date[0][:date_start_full]).to eq(nil)
			expect(date[0][:date_end]).to eq(nil)
			expect(date[0][:date_end_full]).to eq(nil)
			expect(date[0][:inclusive_range]).to eq(nil)
			expect(date[0][:index_dates]).to eq([])
			expect(date[0][:test_data]).to eq(nil)
		end
	end

	it "DOES NOT parse dates that are obviously junk" do
		forms = ["July 4 2776", "July 4 776", "July 4 1776 - July 4 7776", "1897-19??"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq(nil)
			expect(date[0][:date_start_full]).to eq(nil)
			expect(date[0][:date_end]).to eq(nil)
			expect(date[0][:date_end_full]).to eq(nil)
			expect(date[0][:inclusive_range]).to eq(nil)
			expect(date[0][:index_dates]).to eq([])
			expect(date[0][:test_data]).to eq(nil)
		end
	end

	it "parses lists of years" do
		date = Timetwister.parse("1776, 1789, 1812")
		expect(date[0][:date_start]).to eq("1776")
		expect(date[0][:date_start_full]).to eq("1776-01-01")
		expect(date[0][:date_end]).to eq("1776")
		expect(date[0][:date_end_full]).to eq("1776-12-31")
		expect(date[0][:test_data]).to eq("70")

		expect(date[1][:date_start]).to eq("1789")
		expect(date[1][:date_start_full]).to eq("1789-01-01")
		expect(date[1][:date_end]).to eq("1789")
		expect(date[1][:date_end_full]).to eq("1789-12-31")
		expect(date[1][:test_data]).to eq("70")

		expect(date[2][:date_start]).to eq("1812")
		expect(date[2][:date_start_full]).to eq("1812-01-01")
		expect(date[2][:date_end]).to eq("1812")
		expect(date[2][:date_end_full]).to eq("1812-12-31")
		expect(date[2][:test_data]).to eq("70")
	end

	it "parses lists of mixed date types" do
		date = Timetwister.parse("July 1776 - August 1789, 1812 - 1820, 1900")
		expect(date[0][:date_start]).to eq("1776-07")
		expect(date[0][:date_start_full]).to eq("1776-07-01")
		expect(date[0][:date_end]).to eq("1789-08")
		expect(date[0][:date_end_full]).to eq("1789-08-31")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:index_dates]).to eq([1776, 1777, 1778, 1779, 1780, 1781, 1782, 1783, 1784, 1785, 1786, 1787, 1788, 1789])
		expect(date[0][:test_data]).to eq("100")


		expect(date[1][:date_start]).to eq("1812")
		expect(date[1][:date_start_full]).to eq("1812-01-01")
		expect(date[1][:date_end]).to eq("1820")
		expect(date[1][:date_end_full]).to eq("1820-12-31")
		expect(date[1][:inclusive_range]).to eq(true)
		expect(date[1][:index_dates]).to eq([1812, 1813, 1814, 1815, 1816, 1817, 1818, 1819, 1820])
		expect(date[1][:test_data]).to eq("120")

		expect(date[2][:date_start]).to eq("1900")
		expect(date[2][:date_start_full]).to eq("1900-01-01")
		expect(date[2][:date_end]).to eq("1900")
		expect(date[2][:date_end_full]).to eq("1900-12-31")
		expect(date[2][:test_data]).to eq("70")
	end

	it "parses lists with mixed delimiters" do
		date = Timetwister.parse("July 1776 - August 1789; 1812 - 1820, 1900 and June 10-11, 1910")
		expect(date[0][:date_start]).to eq("1776-07")
		expect(date[0][:date_start_full]).to eq("1776-07-01")
		expect(date[0][:date_end]).to eq("1789-08")
		expect(date[0][:date_end_full]).to eq("1789-08-31")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:index_dates]).to eq([1776, 1777, 1778, 1779, 1780, 1781, 1782, 1783, 1784, 1785, 1786, 1787, 1788, 1789])
		expect(date[0][:test_data]).to eq("100")

		expect(date[1][:date_start]).to eq("1812")
		expect(date[1][:date_start_full]).to eq("1812-01-01")
		expect(date[1][:date_end]).to eq("1820")
		expect(date[1][:date_end_full]).to eq("1820-12-31")
		expect(date[1][:inclusive_range]).to eq(true)
		expect(date[1][:index_dates]).to eq([1812, 1813, 1814, 1815, 1816, 1817, 1818, 1819, 1820])
		expect(date[1][:test_data]).to eq("120")

		expect(date[2][:date_start]).to eq("1900")
		expect(date[2][:date_start_full]).to eq("1900-01-01")
		expect(date[2][:date_end]).to eq("1900")
		expect(date[2][:date_end_full]).to eq("1900-12-31")
		expect(date[2][:test_data]).to eq("70")

		expect(date[3][:date_start]).to eq("1910-06-10")
		expect(date[3][:date_start_full]).to eq("1910-06-10")
		expect(date[3][:date_end]).to eq("1910-06-11")
		expect(date[3][:date_end_full]).to eq("1910-06-11")
		expect(date[3][:test_data]).to eq("240")
	end

	it "parses dates with ordinal numbers" do
		forms = ["July twenty-first 1776", "July twenty-first, 1776", "July 21st, 1776", "July 21st 1776"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq("1776-07-21")
			expect(date[0][:date_start_full]).to eq("1776-07-21")
			expect(date[0][:date_end]).to eq("1776-07-21")
			expect(date[0][:date_end_full]).to eq("1776-07-21")
			expect(date[0][:index_dates]).to eq([1776])
			expect(date[0][:test_data]).to eq("200")
		end
	end

	it "parses dates in multiple languages" do
		forms = ["august 4 1776", "août 4 1776", "agosto 4 1776"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq("1776-08-04")
			expect(date[0][:date_start_full]).to eq("1776-08-04")
			expect(date[0][:date_end]).to eq("1776-08-04")
			expect(date[0][:date_end_full]).to eq("1776-08-04")
			expect(date[0][:index_dates]).to eq([1776])
			expect(date[0][:test_data]).to eq("200")
		end
	end

	it "parses dates without clean conjunctions" do
		forms = ["july 4 and 5 1776", "4 & 5 july 1776", "1776 july 4 and 5"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq("1776-07-04")
			expect(date[0][:date_start_full]).to eq("1776-07-04")
			expect(date[0][:date_end]).to eq("1776-07-04")
			expect(date[0][:date_end_full]).to eq("1776-07-04")
			expect(date[0][:index_dates]).to eq([1776])
			expect(date[0][:test_data]).to eq("200")

			expect(date[1][:date_start]).to eq("1776-07-05")
			expect(date[1][:date_start_full]).to eq("1776-07-05")
			expect(date[1][:date_end]).to eq("1776-07-05")
			expect(date[1][:date_end_full]).to eq("1776-07-05")
			expect(date[1][:index_dates]).to eq([1776])
			expect(date[1][:test_data]).to eq("200")
		end

		forms = ["july and august 1776", "1776 july and august"]
		forms.each do |f|
			date = Timetwister.parse(f)
			expect(date[0][:date_start]).to eq("1776-07")
			expect(date[0][:date_start_full]).to eq("1776-07-01")
			expect(date[0][:date_end]).to eq("1776-07")
			expect(date[0][:date_end_full]).to eq("1776-07-31")
			expect(date[0][:index_dates]).to eq([1776])
			expect(date[0][:test_data]).to eq("220")

			expect(date[1][:date_start]).to eq("1776-08")
			expect(date[1][:date_start_full]).to eq("1776-08-01")
			expect(date[1][:date_end]).to eq("1776-08")
			expect(date[1][:date_end_full]).to eq("1776-08-31")
			expect(date[1][:index_dates]).to eq([1776])
			expect(date[1][:test_data]).to eq("220")
		end
	end

	it "parses dates with qualifiers, certainty, and very vague dates" do
		date = Timetwister.parse("ca. mid 19th century")
		expect(date[0][:date_start]).to eq("1830")
		expect(date[0][:date_start_full]).to eq("1830-01-01")
		expect(date[0][:date_end]).to eq("1880")
		expect(date[0][:date_end_full]).to eq("1880-12-31")
	end

	it "parses centuries" do
		date = Timetwister.parse("17th century")
		expect(date[0][:date_start]).to eq('1600')
		expect(date[0][:date_start_full]).to eq("1600-01-01")
		expect(date[0][:date_end]).to eq("1699")
		expect(date[0][:date_end_full]).to eq("1699-12-31")
	end

	it "parses edtf-formatted uncertain dates" do
		date = Timetwister.parse("199u")
		expect(date[0][:date_start]).to eq("1990")
		expect(date[0][:date_start_full]).to eq("1990-01-01")
		expect(date[0][:date_end]).to eq("1999")
		expect(date[0][:date_end_full]).to eq("1999-12-31")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:index_dates]).to eq([1990, 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999])
		expect(date[0][:test_data]).to eq("370")

		date = Timetwister.parse("19uu")
		expect(date[0][:date_start]).to eq("1900")
		expect(date[0][:date_start_full]).to eq("1900-01-01")
		expect(date[0][:date_end]).to eq("1999")
		expect(date[0][:date_end_full]).to eq("1999-12-31")
		expect(date[0][:inclusive_range]).to eq(true)
		expect(date[0][:test_data]).to eq("370")
	end
end