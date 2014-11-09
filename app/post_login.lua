local util = require "utils"
local json = require "resty.libcjson"
local redis = require("resty.redis").new()
local session = require("resty.session").start()

-- timeout: 1s
redis:set_timeout(1000)

local ok, err = redis:connect("127.0.0.1", 6379)
if not ok then
    ngx.log(ngx.ERR, "failed to connect to redis: ", err)
    return ngx.exit(500)
end

ngx.req.read_body()
local args,err = ngx.req.get_post_args()

function get_user(login)
    local res = redis:hgetall(util:redis_key_user(login))
    if not res then
        return
    end
    return redis:array_to_hash(res)
end

-- TODO: evalsha incr script
function attempt_login(login, password)
    local user = get_user(login)

    local kip  = util:redis_key_ip(ngx.var.remote_addr)
    local kuser_fail = util:redis_key_user_fail(login)
    if user and user.password == password then
        local klast = util:redis_key_last(login)
        local knext_last = util:redis_key_next_last(login)
        pcall(redis:rename(knext_last, klast))
        redis:hmset(knext_last, {at=ngx.localtime(), ip=ngx.var.remote_addr })
        redis:mset(kip, 0, kuser_fail, 0)
        ngx.log(ngx.ERR, "** bunned ip count: ", redis:get(kip))
        ngx.log(ngx.ERR, "** locked user count: ", redis:get(kuser_fail))
        return {login = user.login}
    else
        redis:incr(kip)
        redis:incr(kuser_fail)
        ngx.log(ngx.ERR, "** bunned ip count: ", redis:get(kip))
        ngx.log(ngx.ERR, "** locked user count: ", redis:get(kuser_fail))
        return _, "Wrong username or password"
    end
end

user, err = attempt_login(args.login, args.password)

if user then
    session.data.login = user.login
    session:save()
    ngx.redirect("/mypage")
else
    session.data.notice = err
    session:save()
    ngx.redirect("/login")
end
