require 'rubygems'
require 'sinatra'
require 'chronic'
require 'maneki'
require 'moredown'
require 'erb'
require 'haml'
require 'newrelic_rpm'

require 'models'
require 'helpers'


get '/' do
  @posts = Post.index || raise(Sinatra::NotFound)
  haml :index
end


get '/tags/:tag/?' do
  @tag = params[:tag]
  @posts = Post.find_tagged_with(@tag)
  haml :tag
end


get '/archive/?' do
  @posts_by_month_and_year = Post.archive
  haml :archive
end


get '/rss' do
  @posts = Post.index
  content_type 'application/rss+xml'
  erb :rss, layout: false
end


get '/sitemap.xml' do
  @posts = Post.all
  content_type 'text/xml'
  erb :sitemap, :layout => false
end


get '/media/:file.:ext' do
  filename = File.dirname(__FILE__) + '/posts/media/' + params[:file] + '.' + params[:ext]
  if File.file? filename
    send_file(filename)
  else
    raise(Sinatra::NotFound)
  end
end


get '/:slug.text' do
  filename = File.dirname(__FILE__) + '/posts/' + params[:slug] + '.text'
  if File.file? filename
    content_type 'text/plain'
    File.open filename
  end
end


get '/:slug/?' do
  unless render_from_cache(params[:slug])
    @post = Post.find(params[:slug])
    
    if @post
      render_to_cache(params[:slug], haml(:post))
    else
      @keyword = params[:slug].gsub('-', ' ')
      @posts = Post.search(@keyword)
      haml :search
    end
  end
end


before do
  # Redirect to nathanhoad.net
  unless request.env['REMOTE_ADDR'] == '127.0.0.1'
    redirect 'http://nathanhoad.net' if request.env['HTTP_HOST'] != 'nathanhoad.net'
  end
end


not_found do
  haml :not_found
end


def render_to_cache (slug, html)
  filename = File.dirname(__FILE__) + '/cache/' + slug + '.html'
  File.open(filename, 'w') { |f| f.write(html) }
  html
end

def render_from_cache (slug)
  filename = File.dirname(__FILE__) + '/cache/' + slug + '.html'
  if File.file? filename
    send_file(filename)
  else
    false
  end
end