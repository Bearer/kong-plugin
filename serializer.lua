local APPLICATION_NAME = "Kong"

local function canonical_headers(headers)
  local result = {}

  for name, value in pairs(headers) do
    result[name] = type(value) == "table" and value or {value}
  end

  return result
end

local _M = {}

function _M.serialize_request(ngx, kong, path, request_body)
  return {
    logType = "REQUEST",
    requestId = ngx.var.request_id,
    appName = APPLICATION_NAME,
    sourceHostname = ngx.var.remote_addr,
    hostname = ngx.ctx.balancer_data.host,
    path = path,
    -- Request specific
    method = ngx.req.get_method(),
    queryParams = ngx.var.QUERY_STRING,
    requestHeaders = canonical_headers(ngx.req.get_headers()),
    requestBody = request_body
  }
end

function _M.serialize_response(ngx, kong, path, response_body)
  return {
    logType = "RESPONSE",
    requestId = ngx.var.request_id,
    appName = APPLICATION_NAME,
    sourceHostname = ngx.var.remote_addr,
    hostname = ngx.ctx.balancer_data.host,
    path = path,
    -- Response specific
    responseHeaders = canonical_headers(ngx.resp.get_headers()),
    statusCode = ngx.status,
    responseBody = response_body
  }
end

return _M
