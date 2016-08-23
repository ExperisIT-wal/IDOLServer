
--
-- Global vars
--
local monthNames = { 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December' }
local monthNums = { Jan=1, Feb=2, Mar=3, Apr=4, May=5, Jun=6, Jul=7, Aug=8, Sep=9, Oct=10, Nov=11, Dec=12 }
local monthDays = { 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
local daySeconds = 24 * 60 * 60
local leapYears = { 1996, 2008, 1992, 2004, 2016, 2000, 2012 }
local commonYears = { 2001, 2002, 2003, 1998, 1999, 2005, 2006 }

--
-- Helper functions
--
local function dateOfEaster (year)
	-- See http://en.wikipedia.org/wiki/Computus
	local a = year % 19
	local b = math.floor(year / 4)
	local c = math.floor(b / 25) + 1
	local d = math.floor((c * 3) / 4)
	local e = ((a * 19) - math.floor((c * 8 + 5) /  25) + d + 15) % 30
	e = e + math.floor((29578 - a - e * 32) / 1024)
	e = e - ((year % 7) + b - d + e + 2) % 7
	d = math.floor(e / 32)
	-- return year, month, day
	return year, (d + 3), (e - d * 31)
end

local function getCanonicalYear (year)
	-- Map years to an "equivalent" year within the unix epoch
	local a = year - 1
	local janfirst = ((1 + 5 * (a % 4) + 4 * (a % 100) + 6 * (a % 400)) % 7)
	if janfirst == 0 then janfirst = 7 end
	if ((year % 4) == 0 and ((year % 100) ~= 0 or (year % 400) == 0)) then
		-- leap year
		return leapYears[janfirst]
	end
	-- common year
	return commonYears[janfirst]
end

local function getEducedYear (hit, refyear)
	local year = hit['YEAR']
	if year ~= nil then
		return tonumber(year)
	else
		local shortyear = hit['YEARSHORT']
		if shortyear ~= nil then
			-- Only two digits on the year. Assume it's in the current century for starters...
			local yeardiff = tonumber(shortyear) - (refyear % 100)
			if yeardiff > 10 then
				-- Would be more than 10 years in the future, take as being last century
				return refyear + yeardiff - 100
			elseif yeardiff <= -90 then
				-- Would be at least 90 years in the past, take as being next century
				return refyear + yeardiff + 100
			else
				return refyear + yeardiff
			end
		else
			local relyear = hit['REL_YEAR']
			if relyear ~= nil then
				local yeardiff = tonumber(relyear)
				return refyear + yeardiff
			end
		end
	end
	-- Otherwise, return nil
end

--
-- Advanced datetime grammar post-processing
--
-- Input parameters:
--  > hit       - lua table containing educed components
--  > refepoch  - reference point for relative dates ("tomorrow", etc), in epoch seconds
-- Returns a table with the following entries (dates default to today for time only matches):
--  .type       - 'DATETIME' if date & time matched, 'DATE' if date only, 'TIME' if time only
--  .epoch      - matched date & time converted to epoch seconds (if in epoch range)
--  .datetime   - matched date & time as a lua datetime object
--  .datestring - matched date as a string, format "yyyy-mm-dd"
--  .localtimestring - if type is 'TIME' or 'DATETIME", matched time as a string, format "hh:mm:ss"
--  .timestring - if type is 'DATETIME', matched time as a string, format "hh:mm:ss", or "hh:mm:ss ZZZ" if timezone present
--  .timezone   - timezone, if matched
--  .string     - matched date (type 'DATE'), time (type 'TIME') or date & time (type 'DATETIME')
--  .refepoch   - reference point used for relative dates, in epoch seconds
--
function processDateTime( hit, refepoch )
	local refdatetime = os.date('!*t', refepoch)
	local datetime, tzoffset
		
	-- TIMEZONE --
	local tz = hit['TIMEZONE']
	if tz ~= nil then
		-- datetime is considered as UTC, we compute our timezone offset here
		-- and subtract after we have done the conversion to epoch seconds
		datetime = os.date('!*t', refepoch)

		-- format is [+-]hhmm
		local sign, hours, minutes = string.match(tz, "([+-])(%d%d)(%d%d)")
		tzoffset = 3600 * tonumber(hours) + 60 * tonumber(minutes)
		if sign == '-' then
			tzoffset = -tzoffset
		end
	else
		-- no explicit timezone, so in the absence of any other indication, treat
		-- datetime as (server) localtime (which is what IDOL does).
		datetime = os.date('*t', refepoch)

		-- no explicit timezone offset to add after conversion to epoch seconds
		tzoffset = 0
	end
	datetime['hour'], datetime['minute'], datetime['second'] = 12, 0, 0
		
	-- DATE --
	local printdate = true
	local origyearoffset = 0
	local offset = 0
	local mday = hit['DATE']
	local month = hit['MONTH']
	if mday == nil then
		local fixed_date = hit['FIXED_DATE']
		if fixed_date ~= nil then
			mday, month = string.match(fixed_date, "(%d?%d)/(%d?%d)")
		end
	end
	if mday ~= nil then
		-- Absolute date
		datetime['day'] = tonumber(mday)
		if month ~= nil then
			-- Absolute month
			datetime['month'] = tonumber(month)
			local year = getEducedYear(hit, refdatetime['year'])
			if year ~= nil then
				-- Epoch limits workaround
				datetime['year'] = getCanonicalYear(year)
				origyearoffset = year - datetime['year']
			else
				-- No year, assume within 6 months of 'now'
				local refmonth = refdatetime['month']
				local monthdiff = datetime['month'] - refmonth
				if monthdiff > 6 then
					-- Would be more than 6 months into the future if this year, take as being last year instead
					datetime['year'] = datetime['year'] - 1
				elseif monthdiff < -6 then
					-- Would be more than 6 months in the past if this year, take as being next year instead
					datetime['year'] = datetime['year'] + 1
				end
				-- Otherwise implicitly this year
			end
		else
			-- Relative month (implicitly, this month/next month)
			local monthoffset = 0
			local relmonth = hit['REL_MONTH']
			if relmonth ~= nil then
				monthoffset = tonumber(relmonth)
			elseif datetime['day'] < refdatetime['day'] then
				monthoffset = 1
			end
			local newmonth = datetime['month'] + monthoffset
			if newmonth <= 0 then
				datetime['month'] = newmonth + 12
				datetime['year'] = datetime['year'] - 1
			elseif newmonth > 12 then
				datetime['month'] = newmonth - 12
				datetime['year'] = datetime['year'] + 1
			else
				datetime['month'] = newmonth
			end
		end					
	else
		-- Relative date
		local relday = hit['REL_DAY']
		local relweekfromnow = hit['REL_WEEKFROMNOW']
		
		if relday ~= nil then
			-- Number of days relative to today (e.g. tomorrow = +1, yesterday = -1)
			offset = tonumber(relday)
			-- May also have a relative week, e.g. "A week tomorrow"
			if relweekfromnow ~= nil then
				offset = offset + 7 * tonumber(relweekfromnow)
			end
		else
			-- Should have what day of the week
			local weekday = hit['WEEKDAY']
			local weekofmonth = hit['WEEK_OF_MONTH']
			if weekday == nil then
				local dayweekmonth = hit['DAYWEEKMONTH']
				if dayweekmonth ~= nil then
					weekday, weekofmonth, month = string.match(dayweekmonth, "(%d);([+-]?%d);(%d?%d)")
				end
			end
			if weekday ~= nil then
				weekday = tonumber(weekday)
				if weekofmonth ~= nil then
					-- Week in the month, e.g. first Sunday of next month, last Saturday of July
					if month ~= nil then
						datetime['month'] = tonumber(month)
						local year = getEducedYear(hit, refdatetime['year'])
						if year ~= nil then
							datetime['year'] = year
						end
					else
						-- Relative month (implicitly, this month/next month)
						local relmonth = hit['REL_MONTH']
						local newmonth = datetime['month'] + tonumber(relmonth)
						if newmonth <= 0 then
							datetime['month'] = newmonth + 12
							datetime['year'] = datetime['year'] - 1
						elseif newmonth > 12 then
							datetime['month'] = newmonth - 12
							datetime['year'] = datetime['year'] + 1
						else
							datetime['month'] = newmonth
						end						
					end
					-- Find out what the first day of our specified month is using round-trip to epochtime
					datetime['day'] = 1
					datetime = os.date('*t', os.time(datetime) )
					-- Set date to first <weekday> of month
					local refwday = datetime['wday'] - 1
					if weekday > refwday then
						datetime['day'] = 1 + (weekday - refwday)
					elseif weekday < refwday then
						datetime['day'] = 8 - (refwday - weekday)
					end
					-- Now work out what week we should be
					local weeknum = tonumber(weekofmonth)
					if weeknum > 1 then
						datetime['day'] = datetime['day'] + 7 * (weeknum - 1)
					elseif weeknum < 0 then
						-- Use -1 to mean 'last week of month'
						local day = datetime['day']
						while day <= monthDays[datetime['month']] do
							day = day + 7
						end
						datetime['day'] = day + 7 * weeknum
					end
				else
					local relweek = hit['REL_WEEK']
					local relrelweek = hit['REL_REL_WEEK']
					local refwday = datetime['wday'] - 1
					offset = (weekday - refwday)
					
					if relweek ~= nil then
						-- Day in a week given relative to the current week (seen as having started on Sunday/Monday)
						-- e.g. "Tuesday next week"
						offset = offset + 7 * tonumber(relweek)
					else
						-- Number of weeks relative to a day in the next seven days (week starting today)
						-- e.g. "Two weeks on Tuesday", or simply "Wednesday" (i.e. Wednesday of this week)
						if offset < 0 then
							offset = offset + 7
						end
						if relweekfromnow ~= nil then
							offset = offset + 7 * tonumber(relweekfromnow)
						end
					end
					
					if relrelweek ~= nil then
						-- E.g. "Not ... but the one before/after"
						offset = offset + 7 * tonumber(relrelweek)
					end
				end
			else
				-- If we've got all the way down here, likely relative to some moveable feast(!)
				-- (Currently, Easter's the only one we deal with)
				local easteroffset = hit['REL_EASTER']
				if easteroffset ~= nil then
					local year = getEducedYear(hit, refdatetime['year'])
					if year ~= nil then
						-- Easy, they gave us the year!
						datetime['year'], datetime['month'], datetime['day'] = dateOfEaster(year)
					else
						-- Assume this year, or we end up in all sort of trouble trying to get within 6 months...
						datetime['year'], datetime['month'], datetime['day'] = dateOfEaster(refdatetime['year'])
					end
					offset = tonumber(easteroffset)
				else
					-- Fall through all the way; no educed date at all
					printdate = false
				end
			end
		end
	end

	-- Round trip to epochtime to set wday and apply any offset
	local newepoch = os.time(datetime) + (offset * 24 * 60 * 60)
	if tz ~= nil then
		datetime = os.date('!*t', newepoch)
	else
		datetime = os.date('*t', newepoch)
	end
	offset = 0
	local weeksafter = hit['WEEKSAFTER']
	if weeksafter ~= nil then
		local weekdayafter = hit['WEEKDAYAFTER']
		if weekdayafter ~= nil then
			local weekday = tonumber(weekdayafter)
			local refwday = datetime['wday'] - 1
			if weekday > refwday then
				offset = offset + (weekday - refwday) - 7
			elseif weekday < refwday then
				offset = offset - (refwday - weekday)
			end
		end
		offset = offset + 7 * tonumber(weeksafter)
	else
		local weeksbefore = hit['WEEKSBEFORE']
		if weeksbefore ~= nil then
			local weekdaybefore = hit['WEEKDAYBEFORE']
			if weekdaybefore ~= nil then
				local weekday = tonumber(weekdaybefore)
				local refwday = datetime['wday'] - 1
				if weekday > refwday then
					offset = offset + (weekday - refwday)
				elseif weekday < refwday then
					offset = offset - (refwday - weekday) + 7
				end
			end
			offset = offset - 7 * tonumber(weeksbefore)
		end
	end
	local daysafter = hit['DAYSAFTER']
	if daysafter ~= nil then
		offset = offset + tonumber(daysafter)
	end
	local daysbefore = hit['DAYSBEFORE']
	if daysbefore ~= nil then
		offset = offset - tonumber(daysbefore)
	end

	-- Convert offset to seconds and add to/subtract from the current epoch time
	if offset ~= 0 then
		local newepoch = os.time(datetime) + (offset * 24 * 60 * 60)
		if tz ~= nil then
			datetime = os.date('!*t', newepoch)
		else
			datetime = os.date('*t', newepoch)
		end
	end
	
	-- Year fix
	datetime['year'] = datetime['year'] + origyearoffset

	-- TIME --
	local printtime = true
	local hh, mm, ss = 0, 0, 0
	local hour24 = hit['HOUR24']
	if hour24 ~= nil then
		hh = tonumber(hour24)
		if (hh == 10 or hh == 11) and string.upper(hit['AMPM'] or 'AM') == 'PM' then
			hh = hh + 12
		end
	else
		local hour12 = hit['HOUR12']
		if hour12 ~= nil then
			hh = tonumber(hour12)
			if hh == 12 then
				if string.upper(hit['AMPM'] or 'PM') ~= 'PM' then
					-- '12am' or '12 at night'
					hh = 0
				end
			else
				local ampm = string.upper(hit['AMPM'] or 'AM')
				if ampm == 'PM' or (ampm == 'NIGHT' and hh >= 5) then
					hh = hh + 12
				end
			end
		else
			printtime = false
		end
	end
	if printtime then
		local minutes = hit['MINUTES']
		if minutes ~= nil then
			mm = tonumber(minutes)
			local seconds = hit['SECONDS']
			if seconds ~= nil then
                -- expect "second" to be an integer, so forces it to be one
				ss = math.floor(seconds)
			end
		end
		datetime['hour'], datetime['min'], datetime['sec'] = hh, mm, ss
	end

	local result = {}
	result['refepoch'] = os.time(refdatetime)
	result['epoch'] = os.time(datetime)
	if result['epoch'] ~= nil then
		result['epoch'] = result['epoch'] - tzoffset
	end
	result['datetime'] = datetime
	result['datestring'] = string.format('%04d-%02d-%02d', datetime['year'], datetime['month'], datetime['day'])
	if printtime == true then
		result['localtimestring'] = string.format('%02d:%02d:%02d', datetime['hour'], datetime['min'], datetime['sec'])
		if tz ~= nil then
			result['timestring'] = string.format('%s %s', result['localtimestring'], tz)
			result['timezone'] = tz
		else
			result['timestring'] = result['localtimestring']
		end
		if printdate == true then
			result['string'] = string.format('%s %s', result['datestring'], result['timestring'])
			result['type'] = 'DATETIME'
		else
			result['string'] = result['timestring']
			result['type'] = 'TIME'
		end
	else
		result['string'] = result['datestring']
		result['type'] = 'DATE'
	end

	return result
end

--
-- Handler function wrapping main processing routine processDateTime.
-- Any deployment-specific code, e.g. custom date/time format, should go here.
--
function processmatch (edkmatch, request)
	if edkmatch then
		-- The reference date should always be given as UTC
		local refdatetime = os.date('!*t')
		if request and request['refdate'] then
			local refyyyy, refmm, refdd = string.match(request['refdate'], "(%d%d%d%d)-(%d%d)-(%d%d)")
			if refdd ~= nil then
				refdatetime['day'], refdatetime['month'], refdatetime['year'] = refdd, refmm, refyyyy
			end
			local refhh, refmm, refss = string.match(request['refdate'], "(%d%d):(%d%d):(%d%d)")
			if refhh ~= nil then
				refdatetime['hour'], refdatetime['min'], refdatetime['sec'] = refhh, refmm, refss
			end
		end
		local refepoch = os.time(refdatetime)

		-- create structure to pass into processDateTime()
		local components = {}
		for ii = 0, edkmatch:getComponentCount()-1 do
			local component = edkmatch:getComponent(ii)
			components[component:getName()] = component:getText()
		end
		
        -- do the actual processing
		local datetime = processDateTime (components, refepoch)
		
		-- update returned match object
		if datetime and datetime.string then
			edkmatch:setOutputText(datetime.string)
		end
	end
	return true
end
