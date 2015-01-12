local app = {}

-- local methods
function split(str, del)
	p, nrep = str:gsub("%s*"..del.."%s*", "")
	return { str:match((("%s*(.-)%s*"..del.."%s*"):rep(nrep).."(.*)")) }
end

-- class methods
function app:init_redis(redis, _host, _port)
    -- timeout: 1s
    redis:set_timeout(1000)

    local ok, err = redis:connect(_host, _port)
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
function app:get_user(redis, login)
    local res = redis:hgetall(self:key_user(login))
    if not res then
        return
    end
    return redis:array_to_hash(res)
end
function app:ip_banned(redis)
    local kip = self:key_ip(self:get_ip())
    local fail_count = tonumber(redis:get(kip))
    if not fail_count then
        return false
    end
    return fail_count >= conf.ip_ban_threshold
end
function app:user_locked(redis, login)
    local kuser_fail = self:key_user_fail(login)
    local fail_count = tonumber(redis:get(kuser_fail))
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
function app:current_user(redis, login)
	if not login then
		return false
	end
	if not redis:hget(self:key_user(login), "login") then
		return false
	end
	return login
end
function app:attempt_login(redis, login, password)
    local MINCR = redis:script("LOAD", "redis.call('INCR', KEYS[1]); redis.call('INCR', KEYS[2])")

	-- if not login or not password

    local kip = self:key_ip(self:get_ip())
    local kuser_fail = self:key_user_fail(login)

    if self:ip_banned(redis) then
        -- ngx.log(ngx.ERR, "** ip banned:", self:key_ip(self:get_ip()))
        redis:evalsha(MINCR, 2, kip, kuser_fail)
        return nil, "You're banned."
    end

    local user = self:get_user(redis, login)

	if not user then
		redis:evalsha(MINCR, 2, kip, kuser_fail)
    	return nil, "Wrong username or password"
	elseif self:user_locked(redis, login) then
    	redis:evalsha(MINCR, 2, kip, kuser_fail)
    	return nil, "This account is locked."
    elseif user.password == password then
        local klast = self:key_last(login)
        local knext_last = self:key_next_last(login)
        -- pcall(self.redis:rename(knext_last, klast))
        redis:rename(knext_last, klast)
		--ngx.log(ngx.ERR, "---------- last", self.redis:hget(klast, "ip"))

		redis:hmset(knext_last, {at=ngx.localtime(), ip=self:get_ip()})
		--ngx.log(ngx.ERR, "---------- next last", self.redis:hget(knext_last, "ip"))

        -- ngx.log(ngx.ERR, "** success login: ", ngx.localtime(), ", ", self:get_ip())
        redis:mset(kip, 0, kuser_fail, 0)
        return user.login, nil
    else
        redis:evalsha(MINCR, 2, kip, kuser_fail)
        -- ngx.log(ngx.ERR, "** banned ip count: ", kip, "=", redis:get(kip))
        -- ngx.log(ngx.ERR, "** locked user count: ", kuser_fail, "=", redis:get(kuser_fail))
        return nil, "Wrong username or password"
    end
end

return app

