-- @description CSS v1-7 Expressive Auto Legato
-- @author Harry Brokensha
-- @version 0.1
-- @changelog
--  + init

-- hb_Apply Cinematic Studio Strings v1.7 Expressive legato transitions (based on note velocity, leaving note-on of first note and note-off of last note)
-- Thanks to zaibuyidao for the Move Events code.
-- v0.1 (NON REAPACK)

-- Usage:
-- Make sure notes are quantized to the grid before running this tool.
-- Ideally, make sure notes are legato (not overlapping any more than the next note) before using the script, though it shouldn't matter if they aren't.

------------------ USER AREA ---------------------

legato_overlap_notes_after_processing = true

--------------------------------------------------

debug_messages = false

if not reaper.SN_FocusMIDIEditor then
  local retval = reaper.ShowMessageBox("SWS extension required. Go to SWS webpage?", "Warning", 1)
  if retval == 1 then
    Open_URL("http://www.sws-extension.org/download/pre-release/")
  end
end

function msg(param) 
  reaper.ShowConsoleMsg(tostring(param) .. "\n")
end

-- CSS v1.7 Expressive legato transitions offsets:----
slow_offset = -333 --ms
med_offset = -250 --ms
fast_offset = -150 --ms
-------------------------------------------------

slow_offset = slow_offset / 1000
med_offset = med_offset / 1000
fast_offset = fast_offset / 1000


if debug_messages then
  reaper.ClearConsole()
  msg("Slow offset:\t\t"..slow_offset)
  msg("Med offset:\t\t"..med_offset)
  msg("Fast offset:\t\t"..fast_offset)
end


me = reaper.MIDIEditor_GetActive()

function selectParentItem(take, hwnd)
  reaper.MIDI_Sort(take)
  i = reaper.GetMediaItemTake_Item(take)
  reaper.SetMediaItemSelected(i, true)
end

function getFirstSelectedNote(take)
  local _, noteCount = reaper.MIDI_CountEvts(take)
  if debug_messages then
    msg("Total notes: " .. noteCount .. "\n")
  end
  for i = 0, noteCount - 1 do -- loop 
    local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    if selected then
      return i, selected, muted, startppqpos, endppqpos, chan, pitch, vel
    end
  end

  return nil  
end

function getLastSelectedNote(take)
  local _, noteCount = reaper.MIDI_CountEvts(take)
  for i = noteCount - 1, 0, -1 do -- loop in reverse
    local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    if selected then
      return i, selected, muted, startppqpos, endppqpos, chan, pitch, vel
    end
  end

  return nil  
end


function setNoteUnselected(take, noteIndex)
    local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, noteIndex)
    reaper.MIDI_SetNote(take, noteIndex, false, muted, startppqpos, endppqpos, chan, pitch, vel, false)
end

function setNoteSelected(take, noteIndex)
    local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, noteIndex)
    reaper.MIDI_SetNote(take, noteIndex, true, muted, startppqpos, endppqpos, chan, pitch, vel, false)
end

function init()
  take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
  track = reaper.GetMediaItem_Track(reaper.GetMediaItemTake_Item(take))
  track_offset = reaper.GetMediaTrackInfo_Value(track, "D_PLAY_OFFSET")
  if debug_messages then msg("Track offset:\t\t"..track_offset) end

  if not take or not reaper.TakeIsMIDI(take) then return end
  _, notes, ccs, sysex = reaper.MIDI_CountEvts(take)

  --local first_selected_note = reaper.MIDI_EnumSelNotes(take, -1)
  first_selected_note, selected, muted, startppqpos, endppqpos, chan, pitch, vel = getFirstSelectedNote(take)
  if debug_messages then
    msg("First selected note = " .. first_selected_note .. "\n")
  end
  last_selected_note, selected, muted, startppqpos, endppqpos, chan, pitch, vel = getLastSelectedNote(take)
  if debug_messages then
    msg("Last selected note = " .. last_selected_note .. "\n")
  end
end

function NOTES()
  local prev_note_start
  local qqq_prev_note_start
  local prev_note_end
  local qqq_prev_note_end

  cnt_notes_not_changed = 0
  last_notes_of_phrases = {}
  last_notes_of_phrases_note_ends = {}

  for i = 0, notes - 1 do
    local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)

    if debug_messages then
      msg("Iteration i = " .. i .. ", selected = " .. tostring(selected) .. "\n")
    end

    if selected == true and i ~= 0 and i ~= first_selected_note then

      if (vel >= 0 and vel <= 64) then -- slow
        pro_start = (reaper.MIDI_GetProjTimeFromPPQPos(take, startppqpos)) + slow_offset - track_offset
        qqq_pro_start = reaper.MIDI_GetPPQPosFromProjTime(take, pro_start)

        if i ~= last_selected_note then
          pro_end = (reaper.MIDI_GetProjTimeFromPPQPos(take, endppqpos)) + slow_offset - track_offset
        else
          pro_end = (reaper.MIDI_GetProjTimeFromPPQPos(take, endppqpos))
        end
        qqq_pro_end = reaper.MIDI_GetPPQPosFromProjTime(take, pro_end)

        if debug_messages then reaper.ShowConsoleMsg("slow\n\n") end      

      elseif (vel >= 65 and vel <= 100) then -- medium
        pro_start = (reaper.MIDI_GetProjTimeFromPPQPos(take, startppqpos)) + med_offset - track_offset
        qqq_pro_start = reaper.MIDI_GetPPQPosFromProjTime(take, pro_start)

        if i ~= last_selected_note then
          pro_end = (reaper.MIDI_GetProjTimeFromPPQPos(take, endppqpos)) + med_offset - track_offset
        else
          pro_end = (reaper.MIDI_GetProjTimeFromPPQPos(take, endppqpos))
        end
        qqq_pro_end = reaper.MIDI_GetPPQPosFromProjTime(take, pro_end)
       
        if debug_messages then reaper.ShowConsoleMsg("med\n\n") end    

      else -- fast
        pro_start = (reaper.MIDI_GetProjTimeFromPPQPos(take, startppqpos)) + fast_offset - track_offset
        qqq_pro_start = reaper.MIDI_GetPPQPosFromProjTime(take, pro_start)

        if i ~= last_selected_note then
          pro_end = (reaper.MIDI_GetProjTimeFromPPQPos(take, endppqpos)) + fast_offset - track_offset
        else
          pro_end = (reaper.MIDI_GetProjTimeFromPPQPos(take, endppqpos))
        end
        qqq_pro_end = reaper.MIDI_GetPPQPosFromProjTime(take, pro_end)

        if debug_messages then reaper.ShowConsoleMsg("fast\n\n") end        

      end

      if debug_messages then msg("new note start: " .. qqq_pro_start .. "\n") end

      if (qqq_pro_start >= qqq_prev_note_start) and not (qqq_pro_start > qqq_prev_note_end) then
        -- Apply legato transition
        reaper.MIDI_SetNote(take, i, selected, muted, qqq_pro_start, qqq_pro_end, chan, pitch, vel, false)

      elseif qqq_pro_start > qqq_prev_note_end then
        -- Note is first note of new phrase, so store previous noteidx in a list of last notes in phrases
        if debug_messages then msg("Note " .. i .. " not changed: first note of a new phrase.\n") end
        table.insert(last_notes_of_phrases, i - 1)
        table.insert(last_notes_of_phrases_note_ends, qqq_prev_note_end)
      else
        -- Note on would be before previous note (velocity too low for transition)
        if debug_messages then msg("Note " .. i .. " not changed: new note-on position would be before previous note-on.\n") end
        cnt_notes_not_changed = cnt_notes_not_changed + 1
      end 

    end

    -- store new note-on & note-offs for next loop to check
    prev_note_start = (reaper.MIDI_GetProjTimeFromPPQPos(take, startppqpos))
    qqq_prev_note_start = reaper.MIDI_GetPPQPosFromProjTime(take, prev_note_start)
    prev_note_end = (reaper.MIDI_GetProjTimeFromPPQPos(take, endppqpos))
    qqq_prev_note_end = reaper.MIDI_GetPPQPosFromProjTime(take, prev_note_end)

    if debug_messages then 
      msg("qqq_prev_note_start: " .. qqq_prev_note_start .. "\n") 
      msg("qqq_prev_note_end: " .. qqq_prev_note_end .. "\n\n") 
    end

  end
end

function CCS()
  for i = 0, ccs - 1 do
    local retval, selected, muted, ppqpos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, i)
    if selected == true then
      pro_ccstart = (reaper.MIDI_GetProjTimeFromPPQPos(take, ppqpos))
      qqq_pro_ccstart = reaper.MIDI_GetPPQPosFromProjTime(take, pro_ccstart)
      reaper.MIDI_SetCC(take, i, selected, muted, qqq_pro_ccstart, chanmsgIn, chanIn, msg2In, msg3In, false)
    end
  end
end

function SYSEX()
  for i = 0, sysex - 1 do
    local retval, selected, muted, ppqpos, types, msg = reaper.MIDI_GetTextSysexEvt(take, i)
    if selected == true then
      pro_sysstart = (reaper.MIDI_GetProjTimeFromPPQPos(take, ppqpos))
      qqq_pro_sysstart = reaper.MIDI_GetPPQPosFromProjTime(take, pro_sysstart)
      reaper.MIDI_SetTextSysexEvt(take, i, selected, muted, qqq_pro_sysstart, types, msg, false) 
    end
  end
end

function LegatoAndOverlapNotes(overlap)
  local last_selected_note, selected, muted, startppqpos, endppqpos, chan, pitch, vel = getLastSelectedNote(take)
  if last_selected_note then
    setNoteUnselected(take, last_selected_note)
  end

  reaper.MIDIEditor_OnCommand(me, 40405) -- Set note ends to start of next note
  if overlap then
    reaper.MIDIEditor_OnCommand(me, 40444) -- Lengthen notes one pixel
    reaper.MIDIEditor_OnCommand(me, 40444) -- Lengthen notes one pixel
    reaper.MIDIEditor_OnCommand(me, 40444) -- Lengthen notes one pixel
    reaper.MIDIEditor_OnCommand(me, 40444) -- Lengthen notes one pixel
    reaper.MIDIEditor_OnCommand(me, 40444) -- Lengthen notes one pixel
  end

  for i = 1, #last_notes_of_phrases do
    local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, last_notes_of_phrases[i])
    if debug_messages then msg("Note " .. last_notes_of_phrases[i] .. " is last note of phrase: ignoring legato.\n") end
    reaper.MIDI_SetNote(take, last_notes_of_phrases[i], selected, muted, startppqpos, last_notes_of_phrases_note_ends[i], chan, pitch, vel, false)
  end

  if last_selected_note then
    setNoteSelected(take, last_selected_note)
  end
end

function main()
  reaper.Undo_BeginBlock()
  
  init()
  
  reaper.MIDI_DisableSort(take)

  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVESELITEMS1"), 0)

  for takeindex = 1, 100000 do
    take = reaper.MIDIEditor_EnumTakes(reaper.MIDIEditor_GetActive(), takeindex-1, true)
    if take then
      selectParentItem(take, reaper.MIDIEditor_GetActive())
    end
    if not take or not reaper.TakeIsMIDI(take) or not reaper.IsMediaItemSelected(reaper.GetMediaItemTake_Item(take)) then break end
    _, notes, ccs, sysex = reaper.MIDI_CountEvts(take)


    NOTES()
    CCS()
    SYSEX()
    reaper.MIDI_Sort(take)

    if legato_overlap_notes_after_processing then
      LegatoAndOverlapNotes(true)
    end
  end

  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTSELITEMS1"), 0)

  if cnt_notes_not_changed > 0 then
    reaper.ShowMessageBox(cnt_notes_not_changed .. " notes not changed: note-on positions would be before previous note-ons.\n\nTry again with higher velocities (for faster legato transitions).", "Error", 0)
  end


  reaper.Undo_EndBlock("CSS v1.7 Expressive Legato transitions: Move events", -1)
  reaper.UpdateArrange()
  reaper.SN_FocusMIDIEditor()
end

main()