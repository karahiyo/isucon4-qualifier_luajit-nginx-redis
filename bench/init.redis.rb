require 'redis'
require 'mysql2-cs-bind'

def db
  @db = Mysql2::Client.new(
    host: 'localhost',
    port: nil,
    username: 'root',
    password: nil,
    database: 'isu4_qualifier',
    reconnect: true,
  )
end


Thread.new {
  Redis.current.keys('isu4:*').each_slice(1000) { |keys| Redis.current.del(keys) }
}.join


fork {
  @db = nil
  userfails = Hash.new(0)
  ips = Hash.new(0)
  last_logins = {}
  ths = []

  puts "=> SELECT * FROM login_log"
  db.xquery('SELECT * FROM login_log').each do |log|
    user_id, login, ip, ok, at = log.values_at('user_id', 'login', 'ip', 'succeeded', 'created_at')

    if ok == 1
      ips[ip] = 0
      userfails[login] = 0
      last_logins[login] = {ip: ip, at: at.to_i}
    else
      ips[ip] += 1
      userfails[login] += 1 if user_id
    end
  end

  ths << Thread.new do
    last_logins.each do |k, vs|
      Redis.current.hmset("isu4:last:#{k}", vs.to_a.flatten)
    end
    puts " * last"
  end

  ths << Thread.new do
    userfails.each_slice(1000) do |pairs|
      Redis.current.mset(*pairs.flat_map {|v, c| ["isu4:userfail:#{v}", c] })
    end
    puts " * userfail"
  end

  ths << Thread.new do
    ips.each_slice(1000) do |pairs|
      Redis.current.mset(*pairs.flat_map {|v, c| ["isu4:ip:#{v}", c] })
    end
    puts " * ip"
  end

  ths.each(&:join)
}

puts "=> SELECT * FROM users"
db.xquery('SELECT * FROM users').each_slice(10000).with_index do |slice, idx|
  puts "==> users:#{idx}"

  fork {
    users = {}
    slice.each do |user|
      login, password_hash, salt = user.values_at('login', 'password_hash', 'salt')
      users[login] = {password: password_hash, salt: salt, login: login}
    end

    users.each do |k, vs|
      Redis.current.hmset("isu4:user:#{k}", vs.to_a.flatten)
    end
    puts " * users:#{idx}"
  }
end



p Process.waitall
