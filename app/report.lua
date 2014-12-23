local redis = resty_redis:new()
local app = require "../app/app"
app:init_redis(redis, conf.redis.host, conf.redis.port)

local bannedip = {};
local locked_user = {};
for _,ip in pairs(redis:keys("isu4:ip:*")) do
	if tonumber(redis:get(ip)) >= conf.ip_ban_threshold then
		table.insert(bannedip, ip:sub(9))
	end
end
for _,user in pairs(redis:keys("isu4:user_fail:*")) do
	if tonumber(redis:get(user)) >= conf.user_lock_threshold then
		table.insert(locked_user, user:sub(16))
	end
end

local ret = {bannedip=bannedip, locked_user=locked_user};
ngx.say(json.encode(ret));

