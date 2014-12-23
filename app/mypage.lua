local session = require ("resty.session").start()
-- session.cookie.domain = ""
local redis = resty_redis:new()
local app = require "../app/app"
app:init_redis(redis, conf.redis.host, conf.redis.port)

local login = session.data.login
if session.data.current_user then
	login = session.data.current_user
end
local current_user = app:current_user(login)
if session.data.current_user or current_user then
	session.data.current_user = login
	session:save()
	local view = template.new("mypage.html", "base.html")
	view.title = title
	local klast = app:key_last(login)
	local last = redis:hgetall(klast)
	if last then
		local last = redis:array_to_hash(last)
		view.last_logined_at = last.at
		view.last_logined_ip = last.ip
	end
	view.name = session.data.login
	view:render()
else
	session.data.login = nil
	session.data.notice = "You must be logged in"
	session:save()
	ngx.redirect("/")
end

