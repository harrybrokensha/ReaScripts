-- @description Update (open) cue subproject(s) start timecode(s) to positions in master project
-- @author Harry Brokensha
-- @version 1.0
-- @changelog
--  + init

-- NOTE: You must run this project from your master project to avoid unwanted behaviour. There is a warning at the beginning of the script.


-------------[[ USER AREA ]]----------------
--------------------------------------------

-- Set your subproject cue track names here:

cuesTrackNameA = "CUES A" 
cuesTrackNameB = "CUES B"

--------------------------------------------
-----------[[ END USER AREA ]]------------



function msg(m)

	reaper.ShowConsoleMsg(m)

end


function contains(table, val)

    for _, v in ipairs(table) do

        if v == val then
            return true
        end
    end

    return false

end


function trimAfterLastSlash(path)

    return path:match("/([^/]+)$") or path

end


-- unused
function listCues(subProjectsList)

	local cnt = 1

	-- for each ipair in the subprojects list
	for _, itemData in ipairs(subProjectsList) do
		cnt = cnt + 1
	end

end


function getItemStartOffset(item)

	local startpos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

	return startpos

end


function modifyProjectOffset(projIndex, newValue)

	local tab = 3121 + projIndex -- magic number 3121 is the REAPER action for last active tab. 3122 is for tab 1, 3123 for tab 2, etc.

	reaper.Main_OnCommand(tab, 0) -- switch to project tab (3123 = tab 2)

	local cur_offset = reaper.GetProjectTimeOffset(-1, true)

	reaper.SNM_SetDoubleConfigVar('projtimeoffs', cur_offset + reaper.parse_timestr_pos(newValue, 3))

	reaper.Main_OnCommand(3121, 0) -- switch to last active tab

	return true

end


local function isSubProject(take)

    local source = reaper.GetMediaItemTake_Source(take)
    local sourceType = reaper.GetMediaSourceType(source, "")
    return sourceType == "RPP_PROJECT"

end


function getOpenProjectTabs()

	local projMap = {}
	local idx = 0

	while true do

		local retval, projfn = reaper.EnumProjects(idx)

		if retval then
			local filename = projfn
			projMap[filename] = idx + 1 -- store the tab number for this filename
			idx = idx + 1
		else
			-- No more projects found
			break
		end
	end

	return projMap, idx

end

function processSubprojects()

	processCount = 0

	local numTracks = reaper.GetNumTracks()
	local subProjectsList = {}

	-- loop through each track in the project
	for i = 0, numTracks - 1 do

		local track = reaper.GetTrack(0, i)
		local trackName
		retval, trackName = reaper.GetTrackName(track)

		-- if the track name matches either of the cue tracks
		if trackName == cuesTrackNameA or trackName == cuesTrackNameB then

			local itemCount = reaper.GetTrackNumMediaItems(track)

			-- loop through all the items on the track
			for j = 0, itemCount - 1 do

				local item = reaper.GetTrackMediaItem(track, j)
				local take = reaper.GetActiveTake(item)

				-- if there is an item, and the item is a subproject
				if take and isSubProject(take) then

					local takeName = reaper.GetTakeName(take)
					local takeSource = reaper.GetMediaItemTake_Source(take)

					-- add the name, start offset (in s), and filepath to the subProjectsList table
					table.insert(subProjectsList, {
						name = takeName, 
						timecode = getItemStartOffset(item), 
						source = reaper.GetMediaSourceFileName(takeSource, "")
					})

					local lastIndex = #subProjectsList

					-- If the subproject is currently open in one of the project tabs

					local subprojFilename = subProjectsList[lastIndex].source
					
					local tabNumber = openProjectTabs[subprojFilename] -- fetch the tab number from the map

					if tabNumber then -- if we found the tab number

						local success = modifyProjectOffset(tabNumber, reaper.format_timestr_pos(subProjectsList[lastIndex].timecode, '', 5))

						if not success then

							reaper.ShowMessageBox("Error modifying project start offset", "Error", 0)
							
						--else

							--msg("\nProject offset value modified successfully for subproject " .. trimAfterLastSlash(tostring(subProjectsList[lastIndex].source)) .. ".\n")
						end

						processCount = processCount + 1

					--else

						--msg("\nSubproject " .. trimAfterLastSlash(tostring(subProjectsList[lastIndex].source)) .. " is not open. Start offset was not modified.\n")
					end

				else

					reaper.ShowMessageBox("Item is not a subproject on track: " .. trackName .. "\n", "Error", 0)
				end
			end
		end
	end

	-- Debug: Display information about found subprojects.
	-- listCues(subProjectsList)

end



function main()

	local result = reaper.ShowMessageBox("Are you in your master project? If not, press Cancel and switch to your master project tab before running this script.", "Warning", 1)
	
	if result == 1 then

		-- get a list of open project tabs
		openProjectTabs, tabCount = getOpenProjectTabs()

		-- abort if more than 10 tabs (REAPER commands switching limitation to 10 tabs)
		if tabCount > 10 then

			reaper.ShowMessageBox("Error: There are more than 10 tabs open in REAPER. Please close project tabs to continue.", "Aborted", 0)
			return

		end

		processSubprojects()

		reaper.UpdateArrange()

		reaper.ShowMessageBox(processCount .. " open subproject(s) processed successfully.", "Success", 0)

	else return end

end

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Update subprojects' start timecodes", -1)