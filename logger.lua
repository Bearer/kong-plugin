local os = require "os"
local ffi = require "ffi"
local socket = require "socket"
local msgpack = require "MessagePack"
local cjson = require "cjson"

local uint32_a2 = ffi.typeof("uint32_t[2]")
local is_little_endian = ffi.abi("le")

local eventtime_metatable = {}
local function NewEventTime(timestamp_seconds)
  local seconds = math.modf(timestamp_seconds)
  local obj = { seconds = seconds, nano = math.modf((timestamp_seconds - seconds) * 1E9) }
  return setmetatable(obj, eventtime_metatable )
end

local function connect(host, port)
  local fluent = socket.tcp()
  fluent:settimeout(timeout)
  local ok, err = fluent:connect(host or "localhost", port or 24224)
  return fluent, err
end

local function log(premature, plugin_name, conf, timestamp, payload)
  if premature then
    return
  end

  for key, value in pairs(payload) do
    if type(value) == "table" then
      payload[key] = cjson.encode(value)
    end
  end

  -- ngx.log(ngx.ERR, "[" .. plugin_name .. "] log: ", cjson.encode(payload))

  local fluent, err = connect(conf.hostname, conf.port)
  if err then
    ngx.log(ngx.ERR, "[" .. plugin_name .. "] error connecting to collector: ", err)
    return
  end

  local _, err = fluent:send(msgpack.pack({"", NewEventTime(timestamp), payload}))
  if err then
    ngx.log(ngx.ERR, "[" .. plugin_name .. "] error sending log: ", err)
    return
  end

  fluent:close()
end

local _M = {}

function _M.enqueue(plugin_name, conf, timestamp, payload)
  local ok, err = ngx.timer.at(0, log, plugin_name, conf, timestamp, payload)
  if not ok then
    ngx.log(ngx.ERR, "[" .. plugin_name .. "] failed to create timer: ", err)
  end
end

local original_table_packer = msgpack.packers["table"]
msgpack.packers["table"] = function (buffer, value)
  if getmetatable(value) == eventtime_metatable then
    local pieces = is_little_endian and {value.nano, value.seconds} or {value.nano, value.seconds}

    local encoded_value = ffi.string(uint32_a2(pieces), 8)
    if is_little_endian then
      encoded_value = encoded_value:reverse()
    end

    msgpack.packers["fixext8"](buffer, 0, encoded_value)
  else
    original_table_packer(buffer, value)
  end
end

return _M
