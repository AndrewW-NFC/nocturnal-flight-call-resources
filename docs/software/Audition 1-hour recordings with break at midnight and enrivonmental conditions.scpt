```-- Script to automate recordings in Adobe Audition, Waveform Mode
-- Prevent recordings from crossing midnight by splitting at 11:59pm
-- Adds logging to a text file and sets max 1-hour recording duration
-- Now logs weather: surface air temperature, surface (10m) wind, 950 hPa wind, and cloud cover for Arlington, MA

-- Settings
set maxDurationSeconds to 3600 -- max 1 hour recording duration
set pauseBetweenRecordings to 30 -- pause between recordings
set checkIntervalSeconds to 10 -- check time every 10 seconds during recording

-- Define log file path (save to Desktop)
set logFilePath to (path to desktop as text) & "audition_recording_log.txt"

tell application "Adobe Audition 2026"
	activate
end tell

repeat
	-- Create new audio file
	tell application "System Events"
		keystroke "n" using {shift down, command down} -- Shift+Cmd+N
	end tell
	
	delay 10 -- Wait after opening New File dialog
	
	-- Generate filename based on current date/time
	set currentDateTime to do shell script "date '+%Y-%m-%d %H-%M-%S'"
	set fileName to "NFCs starting " & currentDateTime
	
	-- Log: new recording started (with weather)
	my writeToLog("Started new recording: " & fileName)
	
	-- Type the filename
	tell application "System Events"
		keystroke fileName
	end tell
	
	delay 5 -- Wait after typing filename
	
	-- Confirm new file creation
	tell application "System Events"
		keystroke return
	end tell
	
	delay 5 -- Wait after confirming file creation
	
	-- Start recording
	tell application "System Events"
		keystroke space using shift down -- Shift+Space to start recording
	end tell
	
	-- Track recording elapsed time
	set elapsedSeconds to 0
	
	repeat while elapsedSeconds < maxDurationSeconds
		delay checkIntervalSeconds
		set elapsedSeconds to elapsedSeconds + checkIntervalSeconds
		
		-- Check current time
		set currentHourMinute to do shell script "date '+%H:%M'"
		
		if currentHourMinute ≥ "23:59" then
			-- Time to stop before midnight
			exit repeat
		end if
	end repeat
	
	-- Stop recording
	tell application "System Events"
		keystroke space using shift down -- Shift+Space to stop recording
	end tell
	
	-- Log: recording stopped (with weather)
	my writeToLog("Stopped recording: " & fileName)
	
	delay 5
	
	-- Export the file using the same starting timestamp
	tell application "System Events"
		keystroke "e" using {command down, shift down} -- Cmd+Shift+E to open Export Dialog
		delay 5 -- wait for Export dialog to open
		keystroke fileName -- use the same filename as when recording started
		delay 1
		keystroke return -- Confirm Export
	end tell
	
	-- Log: export complete (with weather)
	my writeToLog("Exported file: " & fileName)
	
	-- Pause before next recording or midnight boundary
	delay pauseBetweenRecordings
	
	-- If we stopped due to midnight, wait until 12:01am before starting next recording
	set currentHourMinute to do shell script "date '+%H:%M'"
	if currentHourMinute ≥ "23:59" then
		my writeToLog("Waiting for midnight rollover before starting new recording.")
		repeat
			delay 10
			set currentHourMinute to do shell script "date '+%H:%M'"
			if currentHourMinute ≥ "00:01" then exit repeat
		end repeat
	end if
end repeat

-- =========================
-- Helpers
-- =========================

-- Helper function: fetch weather summary for the current local hour in Arlington, MA
on getWeather()
	try
		-- Arlington, MA coordinates
		set latitude to "42.415"
		set longitude to "-71.156"
		-- Local timezone so hourly timestamps match local clock
		set tz to "America/New_York"
		
		-- Build API URL:
		-- surface air temperature (2m), surface wind (10m), 950 hPa wind, total cloud cover
		-- wind in mph, temperature in Fahrenheit, 1 day horizon
		set apiURL to "https://api.open-meteo.com/v1/forecast?latitude=" & latitude & ¬
			"&longitude=" & longitude & ¬
			"&hourly=temperature_2m,cloud_cover,wind_speed_10m,wind_direction_10m,wind_speed_950hPa,wind_direction_950hPa" & ¬
			"&temperature_unit=fahrenheit&wind_speed_unit=mph&forecast_days=1&timezone=" & tz
		
		set weatherJSON to do shell script "curl -s " & quoted form of apiURL
		
		-- Current hour in API's returned local ISO format (e.g., 2025-09-07T22:00)
		set currentISO to do shell script "date '+%Y-%m-%dT%H:00'"
		
		-- Find index of current hour within the hourly.time array
		set idx to do shell script "echo " & quoted form of weatherJSON & " | jq -r --arg t " & quoted form of currentISO & " '.hourly.time | index($t)'"
		if idx is "" or idx is "null" then return "Weather unavailable"
		
		-- Extract values at that index
		set surfaceTemp to do shell script "echo " & quoted form of weatherJSON & " | jq -r '.hourly.temperature_2m[" & idx & "]'"
		set surfaceWind to do shell script "echo " & quoted form of weatherJSON & " | jq -r '.hourly.wind_speed_10m[" & idx & "]'"
		set surfaceDir to do shell script "echo " & quoted form of weatherJSON & " | jq -r '.hourly.wind_direction_10m[" & idx & "]'"
		set upperWind to do shell script "echo " & quoted form of weatherJSON & " | jq -r '.hourly.wind_speed_950hPa[" & idx & "]'"
		set upperDir to do shell script "echo " & quoted form of weatherJSON & " | jq -r '.hourly.wind_direction_950hPa[" & idx & "]'"
		set cloudCover to do shell script "echo " & quoted form of weatherJSON & " | jq -r '.hourly.cloud_cover[" & idx & "]'"
		
		-- Build a compact, text-only summary
		set weatherSummary to "Surface temp: " & surfaceTemp & "°F | Surface wind: " & surfaceWind & " mph at " & surfaceDir & "° | 950hPa wind: " & upperWind & " mph at " & upperDir & "° | Cloud cover: " & cloudCover & "%"
		return weatherSummary
	on error
		return "Weather unavailable"
	end try
end getWeather

-- Helper function to write to log file (now includes weather)
on writeToLog(logEntry)
	set timeStamp to do shell script "date '+%Y-%m-%d %H:%M:%S'"
	set weatherInfo to my getWeather()
	set fullEntry to timeStamp & " - " & logEntry & " | " & weatherInfo & return
	do shell script "echo " & quoted form of fullEntry & " >> ~/Desktop/audition_recording_log.txt"```
end writeToLog
