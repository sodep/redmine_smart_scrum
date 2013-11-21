require 'redmine'

Redmine::Plugin.register :redmine_smart_scrum do
  name 'Redmine Smart Scrum plugin'
  author 'Humber Aquino'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://localhost:11180/redmine/backlog'
  author_url 'http://example.com/about'

  menu :top_menu, :backlog, { :controller => 'backlog', :action => 'index' }, :caption => 'Backlog'
  menu :top_menu, :scrum_dashboard, { :controller => 'scrum_dashboard', :action => 'index' }, :caption => 'Scrum Dashboard'

end
