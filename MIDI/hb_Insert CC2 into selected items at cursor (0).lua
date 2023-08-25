-- @description Insert CC2 into selected items at cursor (0)
-- @author Harry Brokensha
-- @version 1.0
-- @changelog
--  + init

-- Thanks to Stevie for the select CC functions!

function SelectCC(dest_cc)

  
  local function SelectDestCC(take, item)
    item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION") -- get start of item
    item_start_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, item_start) -- convert item_start_ppq to PPQ

    got_all_ok, midi_string = reaper.MIDI_GetAllEvts(take, "") -- write MIDI events to midi_string, get all events okay
    if not got_all_ok then reaper.ShowMessageBox("Error while loading MIDI", "Error", 0) return(false) end -- if getting the MIDI data failed
    
    midi_len = #midi_string -- get string length
    table_events = {} -- initialize table, MIDI events will temporarily be stored in this table until they are concatenated into a string again
    string_pos = 1 -- position in midi_string while parsing through events 
    sum_offset = 0 -- initialize sum_offset (adds all offsets to get the position of every event in ticks)

    while string_pos < midi_len-12 do -- parse through all events in the MIDI string, one-by-one, excluding the final 12 bytes, which provides REAPER's All-notes-off end-of-take message
      offset, flags, msg, string_pos = string.unpack("i4Bs4", midi_string, string_pos) -- unpack MIDI-string on string_pos
      sum_offset = sum_offset+offset -- add all event offsets to get next start position of event on each iteration
      event_start = item_start_ppq+sum_offset -- calculate event start position based on item start position
      event_type = msg:byte(1)>>4 -- save 1st nibble of status byte (contains info about the data type) to event_type, >>4 shif

      if #msg == 3 -- if msg consists of 3 bytes (= channel message)
      and (msg:byte(1)>>4) == 11  and msg:byte(2) == dest_cc -- if status byte is a CC and CC# equals dest_cc
      then
        flags = flags|1 -- select muted or unmuted event
      end
      table.insert(table_events, string.pack("i4Bs4", offset, flags, msg)) -- re-pack MIDI string and write to table
    end
    reaper.MIDI_SetAllEvts(take, table.concat(table_events) .. midi_string:sub(-12))
    reaper.MIDI_Sort(take)
  end

  -- check, where the user wants to change CCs: MIDI editor, inline editor or arrange view (item)

  local take, item, midi_editor
  local window, _, _ = reaper.BR_GetMouseCursorContext() -- initialize cursor context
  local _, inline_editor, _, _, _, _ = reaper.BR_GetMouseCursorContext_MIDI() -- check if mouse hovers an inline editor

  if window == "midi_editor" then -- MIDI editor focused

    if not inline_editor then -- not hovering inline editor
      take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive()) -- get take from active MIDI editor
      item = reaper.GetMediaItemTake_Item(take) -- get item from take
    
    else -- hovering inline editor (will ignore item selection and only change data in the hovered inline editor)
      take = reaper.BR_GetMouseCursorContext_Take() -- get take from mouse
      item = reaper.GetMediaItemTake_Item(take) -- get item from take
    end

    SelectDestCC(take, item) -- select CC

  else -- anywhere else (apply to selected items in arrane view)
    
    if reaper.CountSelectedMediaItems(0) ~= 0 then
      for i = 0, reaper.CountSelectedMediaItems(0)-1 do -- loop through all selected items
        item = reaper.GetSelectedMediaItem(0, i) -- get current selected item
        take = reaper.GetActiveTake(item)
        
        if reaper.TakeIsMIDI(take) then
          -- if not reaper.BR_IsMidiOpenInInlineEditor(take) then -- is inline editor open?
            -- reaper.Main_OnCommand(40847, 0) -- open inline editor on selected item(s)
          -- end

          SelectDestCC(take, item) -- select CC

        else 
          reaper.ShowMessageBox("Failed: The selected item #".. i+1 .." does not contain a MIDI take and won't be altered", "Error", 0)
        end
      end

    else 
      reaper.ShowMessageBox("Please select at least one item", "Error", 0)
      return false
    end
  end
  reaper.UpdateArrange()
end

function selectCC(cc)
  --package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path
  --require 'sr_Select CC function'

  local dest_cc = cc -- CC

  SelectCC(dest_cc) -- call function
  reaper.Undo_OnStateChange2(proj, "Select CC" .. dest_cc)
end

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

  channel = 0

  ----------------- USER AREA -------------------

  userChannel = 1

  userValue = 0

  userCC = 2

  -----------------------------------------------

  MIDIEditor = reaper.MIDIEditor_GetActive()
  if MIDIEditor == nil then return end

  SelectOnlyMIDIItemsFromSelection()

  -- Get the number of selected media items
  numItems = reaper.CountSelectedMediaItems(0)
  
  -- Loop through all selected media items
  for itemIndex = 0, numItems - 1 do
    item = reaper.GetSelectedMediaItem(0, itemIndex) -- Get the item at the current index
    if item == nil then break end -- Exit the loop if the item is nil

    take = reaper.GetActiveTake(item)
    if take == nil then break end -- Exit the loop if the take is nil
    
    itempos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    itemend = itempos + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')

    if reaper.TakeIsMIDI(take) == false then break end -- Exit the loop if the take ain't MIDI

    pos = reaper.GetCursorPosition() 
    ppq = reaper.MIDI_GetPPQPosFromProjTime(take, pos)

    if pos < itempos then break end -- Exit the loop if the item is after the cursor

    channel = userChannel - 1

    reaper.MIDI_InsertCC(take, 
                          false,--boolean selected, 
                          false,--boolean muted, 
                          ppq,--number ppqpos, 
                          176,--integer chanmsg, 
                          channel,--integer chan, 
                          userCC, 
                          userValue)

    selectCC(userCC)
    --reaper.MIDIEditor_OnCommand(MIDIEditor, 42085) -- Set CC shape to bezier 
    reaper.UpdateItemInProject(item)
  end

  reaper.Main_OnCommand(reaper.NamedCommandLookup("_RS6f45705a69e4a16dd7eacb6343ce05e00e26d568"), 0) -- set selected items CC shape Bezier
end

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Insert CC into selected items at cursor", -1)
reaper.UpdateArrange()