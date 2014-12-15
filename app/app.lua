local app = {
    redis = nil
}

-- local
function split(str, del)
	p, nrep = str:gsub("%s*"..del.."%s*", "")
	return { str:match((("%s*(.-)%s*"..del.."%s*"):rep(nrep).."(.*)")) }
end

-- class
function app:start(_host,_port)
    self.redis = resty_redis:new()

    -- timeout: 1s
    self.redis:set_timeout(1000)

    local ok, err = self.redis:connect(_host, _port)
    if not ok then
        ngx.log(ngx.ERR, "failed to connect to redis: ", err)
        return ngx.exit(500)
    end
end
function app:get_ip()
	local ip = ngx.var.remote_addr
	local xffs = ngx.req.get_headers().x_forwarded_for
	if xffs ~= nil  and ip == conf.localhost then
		ip = split(xffs, ",")[1]
	end
	return ip
end
function app:key_user(login)
    return "isu4:user:"..login
end
function app:key_user_fail(login)
    return "isu4:user_fail:"..login
end
function app:key_ip(ip)
    return "isu4:ip:"..ip
end
function app:key_last(login)
    return "isu4:last:"..login
end
function app:key_next_last(login)
    return "isu4:next_last:"..login
end
function app:get_user(login)
    local res = self.redis:hgetall(self:key_user(login))
    if not res then
        return
    end
    return self.redis:array_to_hash(res)
end
function app:ip_banned()
    local kip = self:key_ip(self:get_ip())
    local fail_count = tonumber(self.redis:get(kip))
    if not fail_count then
        return false
    end
    return fail_count >= conf.ip_ban_threshold
end
function app:user_locked(login)
    local kuser_fail = self:key_user_fail(login)
    local fail_count = tonumber(self.redis:get(kuser_fail))
    if not fail_count then
        return false
    end
    return fail_count >= conf.user_lock_threshold
end
function app:calc_password_hash(password, salt)
 if not password or not salt then
         return ""
 end
 sha256:update(password..":"..salt)
 local digest = sha256:final()
 local ret = str.to_hex(digest)
 return ret
end
function app:current_user(login)
	if not login then
        ngx.log(ngx.ERR, "** return false")
		return false
	end
	if not self.redis:hget(self:key_user(login), "login") then
		return false
	end
	return login
end
function app:attempt_login(login, password)
    local MINCR = self.redis:script("LOAD", "redis.call('INCR', KEYS[1]); redis.call('INCR', KEYS[2])")

    if self:ip_banned() then
        ngx.log(ngx.ERR, "** ip bunned threshould:", conf.ip_ban_threshold)
        ngx.log(ngx.ERR, "** ip bunned:", self:key_ip(self:get_ip()))
        return _, "You're banned."
    end

    if not login or not password then
        return _, "Wrong username or password"
    end
    local user = self:get_user(login)

    if self:user_locked(login) then
        ngx.log(ngx.ERR, "** user locked: ", login)
        return _, "This account is locked."
    end

    local kip = self:key_ip(self:get_ip())
    local kuser_fail = self:key_user_fail(login)
    if user and user.password == password then
        local klast = self:key_last(login)
        local knext_last = self:key_next_last(login)
        -- pcall(self.redis:rename(knext_last, klast))
        self.redis:rename(knext_last, klast)
		--ngx.log(ngx.ERR, "---------- last", self.redis:hget(klast, "ip"))

		self.redis:hmset(knext_last, {at=ngx.localtime(), ip=self:get_ip()})
		--ngx.log(ngx.ERR, "---------- next last", self.redis:hget(knext_last, "ip"))

        ngx.log(ngx.ERR, "** success login: ", ngx.localtime(), ", ", self:get_ip())
        self.redis:mset(kip, 0, kuser_fail, 0)
        return {login = user.login}
    else
        self.redis:evalsha(MINCR, 2, kip, kuser_fail)
        ngx.log(ngx.ERR, "** bunned ip count: ",kip,"=",self.redis:get(kip))
        ngx.log(ngx.ERR, "** locked user count: ",kuser_fail,"=",self.redis:get(kuser_fail))
        return _, "Wrong username or password"
    end
end

return app

