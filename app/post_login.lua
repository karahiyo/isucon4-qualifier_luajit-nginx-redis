local util = require "utils"
local json = require "resty.libcjson"
local redis = require "resty.redis" .new()
local session = require "resty.session" .start()
local conf = require '../app/config'

-- timeout: 1s
redis:set_timeout(1000)

local ok, err = redis:connect(conf.redis.host, conf.redis.port)
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

function ip_banned()
    local kip = util:redis_key_ip(ngx.var.remote_addr)
    local fail_count = tonumber(redis:get(kip))
    if not fail_count then
        return false
    end
    return fail_count >= conf.user_lock_threshold
end

function user_locked(login)
    local kuser_fail = util:redis_key_user_fail(login)
    local fail_count = tonumber(redis:get(kuser_fail))
    if not fail_count then
        return false
    end
    return fail_count >= conf.ip_ban_threshold
end

-- TODO: evalsha incr script
function attempt_login(login, password)
    local user = get_user(login)
    ngx.log(ngx.ERR, "** attempt login: ", login)

    if ip_banned() then
        ngx.log(ngx.ERR, "** ip bunned")
        return _, "You're banned."
    end
    if user_locked(login) then
        ngx.log(ngx.ERR, "** user locked")
        return _, "This account is locked."
    end

    local kip  = util:redis_key_ip(ngx.var.remote_addr)
    local kuser_fail = util:redis_key_user_fail(login)
    if user and user.password == password then
        local klast = util:redis_key_last(login)
        local knext_last = util:redis_key_next_last(login)
        pcall(redis:rename(knext_last, klast))
        redis:hmset(knext_last, {at=ngx.localtime(), ip=ngx.var.remote_addr })
        redis:mset(kip, 0, kuser_fail, 0)
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
