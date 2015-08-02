require 'rubygems'
require 'sinatra'
require 'haml'

configure do
  site_root = '../'
  site_assets = site_root+'source/assets/'
  set :site_root, site_root
  set :site_assets, site_assets
end

# shortcut for calling configs
module Config
  def self.site_root; return Sinatra::Application.settings.site_root; end
  def self.site_assets; return Sinatra::Application.settings.site_assets; end
end

# Handle GET-request (Show the upload form)
get "/" do
  @file_list = _get_file_list()
  haml :upload
end

# Handle POST-request (Receive and save the uploaded file)
post "/upload" do
  target = Config.site_assets + "images/"
  uploaded = params['file_to_upload']
  File.open(target + uploaded[:filename], "w") do |f|
    f.write(uploaded[:tempfile].read)
  end
  system("#{Config.site_root}bin/jekyll_build.bash")
  system("#{Config.site_root}bin/s3_push.bash &")
  redirect "/"
end

post "/remove" do
  path = Config.site_assets + "images/"
  file = params[:name]
  File.unlink(path+file)
  return "removed"
end

def _get_file_list
  files = []
  Dir[Config.site_assets + "images/*"].each do |file|
    path = file
    name = File.basename(path)
    files << {:name => name, :path => path}
  end
  files
end
