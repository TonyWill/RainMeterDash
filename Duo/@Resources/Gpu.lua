-- Highest engine utilization for each adapter.
-- Instance names look like pid_*_luid_0x00000000_0x0000ffc9_phys_0_eng_0_engtype_3d
-- LUIDs are assigned at boot. These match the current Iris Xe and MX450.

local IRIS = "0x0000ffc9"
local NVIDIA = "0x00010890"
local COUNT = 20

local engines

local function maxEngine(buckets)
  local peak = 0
  for _, value in pairs(buckets) do
    if value > peak then
      peak = value
    end
  end
  if peak > 100 then
    peak = 100
  end
  return math.floor(peak + 0.5)
end

function Update()
  if not engines then
    engines = {}
    for i = 1, COUNT do
      engines[i] = SKIN:GetMeasure("MeasureGpu" .. i)
    end
  end

  local iris = {}
  local nvidia = {}

  for i = 1, COUNT do
    local measure = engines[i]
    local value = measure:GetValue()
    if value > 0 then
      local name = string.lower(measure:GetStringValue() or "")
      local luid = name:match("luid_0x[0-9a-f]+_(0x[0-9a-f]+)")
      local engine = name:match("engtype_(.+)$") or "other"
      if luid == IRIS then
        iris[engine] = (iris[engine] or 0) + value
      elseif luid == NVIDIA then
        nvidia[engine] = (nvidia[engine] or 0) + value
      end
    end
  end

  SKIN:Bang("!SetVariable", "IrisGpu", maxEngine(iris))
  SKIN:Bang("!SetVariable", "NvidiaGpu", maxEngine(nvidia))
  SKIN:Bang("!UpdateMeasure", "MeasureIris")
  SKIN:Bang("!UpdateMeasure", "MeasureNvidia")
  return 0
end
