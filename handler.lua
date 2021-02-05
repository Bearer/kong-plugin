local logger = require "kong.plugins.bearer.logger"
local serializer = require "kong.plugins.bearer.serializer"
local BasePlugin = require "kong.plugins.base_plugin"
local url = require "socket.url"
local inspect = require "inspect"
local string = require "string"

local MAX_CONTENT_LENGTH = 1024 * 1024 -- 1mb

local BearerHandler = BasePlugin:extend()

BearerHandler.PRIORITY = -1
BearerHandler.VERSION = "1.0"

local function get_request_body()
  ngx.req.read_body()
  return ngx.req.get_body_data()
end

function BearerHandler:new()
  BearerHandler.super.new(self, "bearer")
end

-- Executed for every request from a client and before it is being proxied to the upstream service
function BearerHandler:access(conf)
  BearerHandler.super.access(self)

  local path = ngx.var.upstream_uri
  kong.ctx.plugin.path = path

  local payload = serializer.serialize_request(ngx, kong, path, get_request_body())
  logger.enqueue(self._name, conf, ngx.req.start_time(), payload)
end

-- Executed when all response headers bytes have been received from the upstream service
function BearerHandler:header_filter(conf)
  BearerHandler.super.header_filter(self)

  local content_length = tonumber(ngx.req.get_headers()["content-length"] or "0")
  if content_length > MAX_CONTENT_LENGTH then
    kong.ctx.plugin.over_size = true
  else
    kong.ctx.plugin.response_body = ""
  end
end

-- Executed for each chunk of the response body received from the upstream service
function BearerHandler:body_filter(conf)
  BearerHandler.super.body_filter(self)

  if kong.ctx.plugin.over_size then
    return
  end

  local chunk = ngx.arg[1] or ""
  local response_body = kong.ctx.plugin.response_body

  if string.len(response_body) + string.len(chunk) > MAX_CONTENT_LENGTH then
    kong.ctx.plugin.over_size = true
    kong.ctx.plugin.response_body = nil
    return
  end

  kong.ctx.plugin.response_body = response_body .. chunk
end

-- Executed when the last response byte has been sent to the client
function BearerHandler:log(conf)
  BearerHandler.super.log(self)

  local payload = serializer.serialize_response(ngx, kong, kong.ctx.plugin.path, kong.ctx.plugin.response_body)
  logger.enqueue(self._name, conf, ngx.now(), payload)
end

return BearerHandler
