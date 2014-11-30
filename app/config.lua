local conf = {
	localhost = "127.0.0.1",
	port = 8080,
    ip_ban_threshold = 10,
    user_lock_threshold = 3,
    redis = {
        host = "127.0.0.1",
        port = 6379
    }
}
return conf
