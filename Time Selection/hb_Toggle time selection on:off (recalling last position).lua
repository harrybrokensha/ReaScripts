-- @description Toggle time selection (recalling last position)
-- @author Harry Brokensha
-- @version 1.0
-- @changelog
--  + init

local r = reaper

if not reaper.SN_FocusMIDIEditor then
  local retval = reaper.ShowMessageBox("Please install the SWS extension from the following URL to use this script:", "SWS Extension required", 1)
  if retval == 1 then
    Open_URL("http://www.sws-extension.org/download/pre-release/")
  end
end

function timeSelExists()
	starttime, endtime = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)

	if starttime == endtime then
	  return false
	else
	  return true
	end
end

function main()
	if timeSelExists() then
		r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVETIME1"), 0) -- SWS: Save time selection
		r.Main_OnCommand(40020, 0) -- Remove (unselect) time selection and loop points
	else
		r.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTTIME1"), 0) -- SWS: Restore time selection
	end
end

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Toggle time selection on/off", -1)
reaper.UpdateArrange()