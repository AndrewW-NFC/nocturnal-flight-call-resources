-- Script to automate recordings in Adobe Audition, Waveform Mode
-- Prevent recordings from crossing midnight by splitting at 11:59pm
-- Adds logging to a text file and sets max 1-hour recording duration
-- Logs weather: surface air temperature, surface (10m) wind, 950 hPa wind, and cloud cover for Arlington, MA
-- Stops for the morning at finalStopTime, confirms final export, then launches BirdNET and Nighthawk analysis

-- =========================
-- Settings
-- =========================

set maxDurationSeconds to 3600 -- max 1 hour recording duration
set pauseBetweenRecordings to 30 -- pause between recordings
set checkIntervalSeconds to 10 -- check time every 10 seconds during recording

-- Final morning stop time.
-- This is interpreted as a morning time, so 06:15 means 6:15am the morning after the session begins.
set finalStopTime to "06:15"

-- Session date should represent the evening the recording session began,
-- not the morning when analysis runs.
set sessionDate to do shell script "date '+%Y-%m-%d'"

-- Desktop paths
set desktopPOSIX to POSIX path of (path to desktop)
set logFilePath to (path to desktop as text) & "audition_recording_log.txt"
set analysisScriptPath to desktopPOSIX & "analyze_last_night.zsh"
set analysisHasRun to false

tell application "Adobe Audition 2026"
	activate
end tell

repeat
	set reachedFinalStop to false
	
	-- Create new audio file
	tell application "System Events"
		keystroke "n" using {shift down, command down} -- Shift+Cmd+N
	end tell
	
	delay 10 -- Wait after opening New File dialog
	
	-- Generate filename based on current date/time
	set currentDateTime to do shell script "date '+%Y-%m-%d %H-%M-%S'"
	set fileName to "NFCs starting " & currentDateTime
	
	-- Log: new recording started
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
		
		-- Stop for final morning cutoff.
		-- Important: simple string comparison would make evening times such as 20:00 look "after" 06:15.
		-- Therefore, only treat finalStopTime as active before noon.
		if my isMorningFinalStop(currentHourMinute, finalStopTime) then
			set reachedFinalStop to true
			exit repeat
		end if
		
		-- Stop before midnight so files do not cross calendar dates
		if currentHourMinute ≥ "23:59" then
			exit repeat
		end if
	end repeat
	
	-- Stop recording
	tell application "System Events"
		keystroke space using shift down -- Shift+Space to stop recording
	end tell
	
	-- Log: recording stopped
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
	
	-- Confirm the WAV exists and has stopped growing
	set exportedWavPath to my waitForDesktopExportToFinish(fileName)
	
	-- Log: export complete
	my writeToLog("Export confirmed complete: " & exportedWavPath)
	
	-- If this was the final morning stop, launch analysis and end the script
	if reachedFinalStop is true and analysisHasRun is false then
		set analysisHasRun to true
		my writeToLog("Final morning recording exported. Starting BirdNET and Nighthawk analysis for session date: " & sessionDate)
		
		-- Run with /bin/zsh so the shell script does not need executable permissions.
		do shell script "/bin/zsh " & quoted form of analysisScriptPath & " " & quoted form of sessionDate & " > ~/Desktop/nfc_analysis_log.txt 2>&1 &"
		
		exit repeat
	end if
	
	-- Pause before next recording or midnight boundary
	delay pauseBetweenRecordings
	
	-- If we stopped due to midnight, wait until after midnight before starting new recording
	set currentHourMinute to do shell script "date '+%H:%M'"
	if currentHourMinute ≥ "23:59" then
		my writeToLog("Waiting for midnight rollover before starting new recording.")
		repeat
			delay 10
			set currentHourMinute to do shell script "date '+%H:%M'"
			if currentHourMinute starts with "00:" then exit repeat
		end repeat
	end if
end repeat

-- =========================
-- Helpers
-- =========================

-- Interpret finalStopTime as a morning cutoff.
-- Example:
-- currentHourMinute = "06:15", finalStopTime = "06:15" -> true
-- currentHourMinute = "20:00", finalStopTime = "06:15" -> false
on isMorningFinalStop(currentHourMinute, finalStopTime)
	if currentHourMinute < "12:00" and currentHourMinute ≥ finalStopTime then
		return true
	else
		return false
	end if
end isMorningFinalStop

-- Wait until the exported WAV appears on the Desktop and its size stops changing.
on waitForDesktopExportToFinish(fileName)
	set desktopPOSIX to POSIX path of (path to desktop)
	set wavPath to desktopPOSIX & fileName & ".wav"
	
	-- Wait up to 20 minutes for the file to appear
	set fileAppeared to false
	repeat with i from 1 to 240
		set fileExists to do shell script "test -f " & quoted form of wavPath & " && echo yes || echo no"
		if fileExists is "yes" then
			set fileAppeared to true
			exit repeat
		end if
		delay 5
	end repeat
	
	if fileAppeared is false then
		my writeToLog("Warning: expected exported WAV did not appear: " & wavPath)
		return wavPath
	end if
	
	-- Wait until file size is stable across three checks
	set stableChecks to 0
	set previousSize to "-1"
	
	repeat with i from 1 to 120
		set currentSize to do shell script "stat -f%z " & quoted form of wavPath
		if currentSize is previousSize then
			set stableChecks to stableChecks + 1
		else
			set stableChecks to 0
			set previousSize to currentSize
		end if
		
		if stableChecks ≥ 3 then exit repeat
		
		delay 5
	end repeat
	
	return wavPath
end waitForDesktopExportToFinish

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
		
		-- Current hour in API's returned local ISO format
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

-- Helper function to write to log file
on writeToLog(logEntry)
	set timeStamp to do shell script "date '+%Y-%m-%d %H:%M:%S'"
	set weatherInfo to my getWeather()
	set fullEntry to timeStamp & " - " & logEntry & " | " & weatherInfo & return
	do shell script "echo " & quoted form of fullEntry & " >> ~/Desktop/audition_recording_log.txt"
end writeToLog
