local session = require ("resty.session").start()

ngx.req.read_body()

local args,err = ngx.req.get_post_args()

-- TODO: evalsha incr script
function attempt_login(login, password)
    local user = app:get_user(login)
    ngx.log(ngx.ERR, "** attempt login: ", login)

    if app:ip_banned() then
        ngx.log(ngx.ERR, "** ip bunned")
        return _, "You're banned."
    end
    if app:user_locked(login) then
        ngx.log(ngx.ERR, "** user locked")
        return _, "This account is locked."
    end

    local kip  = app:redis_key_ip(ngx.var.remote_addr)
    local kuser_fail = app:redis_key_user_fail(login)
    if user and user.password == password then
        local klast = app:redis_key_last(login)
        local knext_last = app:redis_key_next_last(login)
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
