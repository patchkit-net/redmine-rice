Redmine::Plugin.register :rice_reports do
  name 'Rice Reports plugin'
  author 'Piotr Korzuszek'
  description 'RICE reports'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  permission :report, { :report => [:index, :vote] }, :public => true
  menu :project_menu, :report, { :controller => 'report', :action => 'index' }, :caption => 'RICE', :after => :activity, :param => :project_id

  settings default: {
    'reach_weight' => 1,
    'impact_weight' => 4,
    'confidence_weight' => 2
  }, partial: 'settings/rice_reports_settings'
end
