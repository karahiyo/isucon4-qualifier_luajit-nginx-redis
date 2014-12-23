local session = require ("resty.session").start()
-- session.cookie.domain = ""
local redis = resty_redis:new()

-- get post data
ngx.req.read_body()
local args, err = ngx.req.get_post_args()

if args then
	app:init_redis(redis, conf.redis.host, conf.redis.port)
	user, notice = app:attempt_login(args.login, args.password)
end

if user then
	session.data.login = user
	session:save()
	ngx.redirect("/mypage")
else
	session.data.notice = notice
	session:save()
	ngx.redirect("/")
end

