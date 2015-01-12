local redis = resty_redis:new()
local app = require "../app/app"
app:init_redis(redis, conf.redis.host, conf.redis.port)

local banned_ips = {};
local locked_users = {};
for _,ip in pairs(redis:keys("isu4:ip:*")) do
	if tonumber(redis:get(ip)) >= conf.ip_ban_threshold then
		table.insert(banned_ips, ip:sub(9))
	end
end
for _,user in pairs(redis:keys("isu4:user_fail:*")) do
	if tonumber(redis:get(user)) >= conf.user_lock_threshold then
		table.insert(locked_users, user:sub(16))
	end
end

local ret = {banned_ips=banned_ips, locked_users=locked_users};
ngx.say(json.encode(ret));

