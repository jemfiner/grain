--  
--   ////\\\\
--   ////\\\\ grain record version
--   ////\\\\  
--   \\\\////
--   \\\\////  
--   \\\\////
--
--  
--  load sample into buffer 2 (parameters) or record into buffer 1
--  key 1: alt
--  key 2: toggles record
--  key 3: starts play
--  enc 2: increment amount
--  enc 2 + alt: root note (rate)
--  enc 3: chord select for pitch dispersion 
--  enc 3 + alt: pitch dispersion
--
--  the higher the value of pitchDisp, the wider the span of notes from the chord
--  to do: among other things, add interval as variable (& root note via midi ?)

engine.name = 'oneGrain3'

local music = require 'musicutil'
local scaleLength = 16
local chordLength = 3
local chordRoot = 0
local mode = math.random(#music.CHORDS)
--scale = music.generate_scale_of_length(60,music.SCALES[mode].name,8)
local chord = music.generate_chord(60,'minor')
local scale = music.generate_scale_of_length(60,'chromatic',scaleLength)
local rates = {}

--'midi note as rate '= (1 + (scale[position]-60)/12)

local midi_signal_in
local midi_signal_out
local viewport = { width = 128, height = 64, frame = 0 }
local overdub = 0.5
local duration = 1
local density = 0.25
local count = 0
local speed = 150
--local rates = {0.5,0.66, 0.75, 1, 1.33, 1.5}
local basePitch = 1
local rate = 1
local pitchDisp = 1
local pitchQ = 0
local pan = 0.75
local amp = 0.5
local timeDisp = 0
local timeDispDivisor = 1
local length = 0
local start = 0
local alt = false
local recToggle = 0
local inc = 1
local divisor = 1
local buffers = {'buffer', 'recBuffer'}

-- Main

function init()
  local sep = ": "
  local v = 1
  params:add_file("sample", "sample")
  params:set_action("sample", function(file) engine.read(file) end)
  
  params:add_number("whichBuffer","whichBuffer",1,2,1)
  params:set_action("whichBuffer", function(x) engine.whichBuffer(x) end)
  
  params:set("monitor_level",-math.huge)
  
  cs_overdub = controlspec.new(0.0,1.0,'lin',0,0.5,'')
  params:add{type="control",id="overdub",controlspec=cs_overdub,
    action=function(x) overdub = x end}
  
  cs_duration = controlspec.new(0.0125,4.0,'lin',0,1,'')
  params:add{type="control",id="duration",controlspec=cs_duration,
    action=function(x) duration = x end}
  
  cs_density = controlspec.new(0.025,4.0,'lin',0,0.25,'')
  params:add{type="control",id="density",controlspec=cs_density,
    action=function(x) density = x end}
  
  --params:add_number("increment","increment",1,16,4)
  --params:set_action("increment", function(x) divisor = x end)
  
  --params:add_number("timeDisp","timeDisp",0,440,0)
  --params:set_action("timeDisp", function(x) timeDisp = x end)
  
  params:add_number("timeDisp","timeDisp",1,16,1)
  params:set_action("timeDisp", function(x) timeDispDivisor = x increment() end)
  
  --cs_pitch = controlspec.new(-4.0,4.0,'lin',0,1,'')
  --params:add{type="control",id="pitch",controlspec=cs_pitch,
    --action=function(x) basePitch = x end}
  
  
  --cs_pitchDisp = controlspec.new(0.0,2.0,'lin',0,0,'')
  --for pitch variation based on scale
  --cs_pitchDisp = controlspec.new(0,scaleLength,'lin',0,0,'')
  --params:add{type="control",id="pitchDisp",controlspec=cs_pitchDisp,
    --action=function(x) pitchDisp = x end}
    
 -- params:add_number("pitchDisp","pitchDisp",1,7,1)
  --params:set_action("pitchDisp", function(x) pitchDisp = x pitch() end)
  
  --cs_pitchQ = controlspec.new(0.0,1.0,'lin',0,0,'')
  --params:add{type="control",id="pitchQ",controlspec=cs_pitchQ,
    --action=function(x) pitchQ = x end}
  
  cs_pan = controlspec.new(0.0,1.0,'lin',0,0.75,'')
  params:add{type="control",id="pan",controlspec=cs_pan,
    action=function(x) pan = x end}
  
  cs_amp = controlspec.new(0,1,'lin',0,0.5,'')
  params:add{type="control",id="amp",controlspec=cs_amp,
    action=function(x) amp = x end}
  
  params:bang()
  
  p = poll.set("length")
  p.callback = function(val) length = val print("length in samples > "..length) end
  p.time = 1
  p:start()
  
  --scale as pitch rate
  rateCalc()
  
  -- Render Style
  screen.level(15)
  screen.aa(0)
  screen.line_width(1)
  -- Render
  redraw()
  
end

function rateCalc()
  rates = {}
  for i = 1,#chord do
    print(i, chord[i])
    table.insert(rates,(1 + (chord[i]-60)/12))
    print(' ', rates[i])
  end
end

function pitch()
  --calculate pitch here
  local variation
  variation = rates[math.random(pitchDisp)]
  if pitchDisp == 1 then
    rate = basePitch
    else
    rate = math.random(2) == 1 and basePitch + variation - 1 or basePitch - (variation - 1)
  end
  print('basePitch ', basePitch, 'rate ',rate)
end

function startPoint()
  --calculate start point here, not in engine
  --(start + Rand(timeDisp.neg,timeDisp))%BufFrames.kr(bufnum)
  --start = ((count * speed) + math.random(-timeDisp,timeDisp))%length
  start = ((count * inc) + math.random(-timeDisp,timeDisp))%length
  if (start + (duration * 48000)) > length then
    start = 0
    else start = start
  end
  print("start ",start)
end

function increment()
  --calculate increment here
  --read divisor from encoder
  inc = math.floor(length / 2^(16-divisor))
  timeDisp = math.floor(length / 2^(16-timeDispDivisor))
end

function continuous()
  while true do
    clock.sleep(density)
    startPoint()
    pitch()
    engine.rate(rate)
    --rate chosen randomly from scale
    --engine.rate(rates[math.random(1,#rates)])
    engine.pitchDisp(pitchDisp)
    engine.pitchQ(pitchQ)
    --engine.rate(rates[math.random(#rates)])
    --engine.start(count * speed) -- speed being increment in samples
    engine.start(start)
    --engine.timeDisp(timeDisp*100)
    engine.timeDisp(timeDisp)
    engine.amp(amp)
    engine.duration(duration)
    engine.pan(pan)
    engine.overdub(overdub)
    redraw()
    count = count + 1
 end
end

-- Interactions

function key(id,state)
    if id == 1
    then  alt = state == 1
    end
    if id == 2 and state == 1 then
     if recToggle == 1 then
        recToggle = 0
        print('recording off')
        engine.recordButton(0)
     else
       engine.recordButton(1)
       print('recording on !')
       recToggle = 1
     end
    end
    if id == 3 and state == 1 then
    --clock.run(strum, math.random(16), math.random(8))
    clock.run(continuous)
    --print('grain')
    --engine.rate(math.random(4.0))
    --engine.start(math.random(4)*44100)
    --engine.duration(0.125)
    --engine.pan(1.0)
  end
  redraw()
end

function enc(id,delta)
   if id == 1 then
     alt = true
   end
   if id == 2 then
     if alt == false then
      divisor = clamp(divisor + delta,1,16)
      increment()
     else
      chordRoot = clamp(chordRoot + delta,-24,24)
      basePitch = 1 + chordRoot/12
      print('chord root ', chordRoot, 'base pitch ', basePitch)
     end
   end
   if id == 3 then
     if alt == false then
     mode = util.clamp(mode + delta , 1, #music.CHORDS)
     chord = music.generate_chord(60,music.CHORDS[mode].name)
     chordLength = #chord
     if pitchDisp > chordLength then
       pitchDisp = chordLength
     end
     print('chord length ', chordLength)
     rateCalc()
     else
     pitchDisp = util.clamp(pitchDisp + delta, 1, chordLength)
     print('pitch disp ', pitchDisp)
     pitch()
     end
   end

   
  redraw()
end

function draw()
  screen.move(0,10)
  screen.text('root')
  screen.move(20,10)
  screen.text(string.format("%.3f",basePitch))
  screen.move(90,10)
  screen.text('pitch d')
  screen.move(123,10)
  screen.text(pitchDisp)
  screen.move((120/length)*start,30)
  screen.text('I')
  screen.move(0,50)
  screen.text('increment ')
  screen.move(45,50)
  screen.text(inc)
  screen.move(0,60)
  screen.text('scale')
  screen.move(45,60)
  screen.text(music.CHORDS[mode].name)
  screen.move(100,50)
  screen.text('rec')
  screen.move(115,50)
  if recToggle == 1 then
    screen.text('on')
  else screen.text('off')
  end 
end

function redraw()
  screen.clear()
  draw()
  screen.stroke()
  screen.update()
end

-- Utils

function print_info(file)
  --if util.file_exists(_path.dust..file) == true then
  if util.file_exists(file) == true then
    ch, samples, samplerate = audio.file_info(file) -- FIXME: audio.file_info uses audio path??? without /home/we/dust ?
    fileDuration = samples/samplerate
    print("loading file: "..file)
    print("  channels:\t"..ch)
    print("  samples:\t"..samples)
    print("  sample rate:\t"..samplerate.."hz")
    print("  duration:\t"..fileDuration.." sec")
  else print "read_wav(): file not found" end
end

function clamp(val,min,max)
  return val < min and min or val > max and max or val
end

function note_to_hz(note)
  return (440 / 32) * (2 ^ ((note - 9) / 12))
end
