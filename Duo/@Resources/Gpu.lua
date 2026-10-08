-- GPU RAM per adapter. Iris Xe uses shared system memory. The MX450 uses dedicated VRAM.
-- Instance names look like luid_0x00000000_0x0001000c_phys_0
-- LUIDs and capacities are assigned at boot. Customize > Refresh GPU ids rewrites them.

local IRIS = "0x0001000c"
local NVIDIA = "0x000108d3"
local IRIS_MAX = 8428038144
local NVIDIA_MAX = 1999040512
local COUNT = 4

local dedicated
local shared

local function fmt(bytes)
  if bytes >= 1073741824 then
    return string.format("%.1fG", bytes / 1073741824)
  end
  return string.format("%.0fM", bytes / 1048576)
end

local function pct(bytes, cap)
  if cap < 1 then
    return 0
  end
  local p = math.floor(bytes / cap * 100 + 0.5)
  if p > 100 then
    p = 100
  end
  return p
end

local function grab(measures, i)
  local measure = measures[i]
  local name = string.lower(measure:GetStringValue() or "")
  local luid = name:match("luid_0x[0-9a-f]+_(0x[0-9a-f]+)")
  if not luid then
    return nil, 0
  end
  return luid, measure:GetValue()
end

function Update()
  if not dedicated then
    dedicated = {}
    shared = {}
    for i = 1, COUNT do
      dedicated[i] = SKIN:GetMeasure("MeasureGpuDed" .. i)
      shared[i] = SKIN:GetMeasure("MeasureGpuShare" .. i)
    end
  end

  local ded = {}
  local sh = {}
  for i = 1, COUNT do
    local luid, value = grab(dedicated, i)
    if luid then
      ded[luid] = value
    end
    luid, value = grab(shared, i)
    if luid then
      sh[luid] = value
    end
  end

  local irisBytes = (ded[IRIS] or 0) + (sh[IRIS] or 0)
  local nvidiaBytes = ded[NVIDIA] or 0

  SKIN:Bang("!SetVariable", "IrisGpu", pct(irisBytes, IRIS_MAX))
  SKIN:Bang("!SetVariable", "NvidiaGpu", pct(nvidiaBytes, NVIDIA_MAX))
  SKIN:Bang("!SetVariable", "IrisGpuLabel", fmt(irisBytes))
  SKIN:Bang("!SetVariable", "NvidiaGpuLabel", fmt(nvidiaBytes))
  SKIN:Bang("!UpdateMeasure", "MeasureIris")
  SKIN:Bang("!UpdateMeasure", "MeasureNvidia")
  SKIN:Bang("!UpdateMeter", "MeterIrisValue")
  SKIN:Bang("!UpdateMeter", "MeterNvidiaValue")
  return 0
end
