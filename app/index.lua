local session = require ("resty.session").start()
-- session.cookie.domain = ""
local view = template.new("login.html", "base.html")

view.title = title
if session.data.notice then
	view.notice = session.data.notice
end
view:render()

