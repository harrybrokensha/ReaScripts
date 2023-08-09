-- @description Select only audio items (from selection)
-- @author Harry Brokensha
-- @version 1.0
-- @changelog
--  + init versions

function SelectOnlyAudioItemsFromSelection()
	numItems = reaper.CountSelectedMediaItems(0)

	for itemIndex = 0, numItems - 1 do
		item = reaper.GetSelectedMediaItem(0, itemIndex) -- Get the item at the current index
	    if item == nil then break end -- Exit the loop if the item is nil

	    take = reaper.GetActiveTake(item)
	    if take == nil then break end -- Exit the loop if the take is nil

	    if reaper.TakeIsMIDI(take) == true then
	    	reaper.SetMediaItemSelected(item, false)
	    end
	end
end

function main()
	reaper.Undo_BeginBlock()

	SelectOnlyAudioItemsFromSelection()
	
	reaper.Undo_EndBlock("Set only audio items selected from selection", -1)
	reaper.UpdateArrange()
end

main()