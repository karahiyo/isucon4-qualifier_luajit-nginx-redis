local session = require ("resty.session").start()
-- session.cookie.domain = ""
session.cookie.domain = ".ec2-54-65-221-166.ap-northeast-1.compute.amazonaws.com"
local view = template.new("login.html", "base.html")

view.title = title
if session.data.notice then
	view.notice = session.data.notice
end
view:render()

