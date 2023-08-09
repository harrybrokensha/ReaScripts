-- @description Select only MIDI items (from selection)
-- @author Harry Brokensha
-- @version 1.0
-- @about

function SelectOnlyMIDIItemsFromSelection()
	numItems = reaper.CountSelectedMediaItems(0)

	for itemIndex = 0, numItems - 1 do
		item = reaper.GetSelectedMediaItem(0, itemIndex) -- Get the item at the current index
	    if item == nil then break end -- Exit the loop if the item is nil

	    take = reaper.GetActiveTake(item)
	    if take == nil then break end -- Exit the loop if the take is nil

	    if reaper.TakeIsMIDI(take) == false then
	    	reaper.SetMediaItemSelected(item, false)
	    end
	end
end

function main()
	reaper.Undo_BeginBlock()

	SelectOnlyMIDIItemsFromSelection()
	
	reaper.Undo_EndBlock("Set only MIDI items selected from selection", -1)
	reaper.UpdateArrange()
end

main()