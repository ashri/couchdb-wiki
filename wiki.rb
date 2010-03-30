require 'rubygems'
require 'sinatra'
require 'json'
require 'couchrest'
require 'maruku'

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end

def database_name
  YAML.load_file("config.yml")['database']
end

db = CouchRest.database("http://localhost:5984/#{database_name}")

error do
  e = request.env['sinatra.error']
  Kernel.puts e.backtrace.join("\n")
  "Application error"
end

helpers do
  # add your helpers here
end

# root page
get '/' do
  spaces = db.view("spaces/by_slug?group=true")
  if spaces
    @spaces = []
    spaces["rows"].each do |s|
      @spaces << { :slug => slug(s['key']), :title => s['key'], :doc_count => s['value'] }
    end
  end
  recent_changes = db.view("documents/recent?descending=true")
  if recent_changes
    @recent_changes = []
    recent_changes["rows"].slice(0, 10).each do |d|
      date = Date.parse(d['key']).strftime("%d/%m/%Y %p") if d['key']
      @recent_changes << { :slug => "#{slug(d['value']['space'])}/#{d['value']['slug']}",
                           :space => d['value']['space'],
                           :space_slug => slug(d['value']['space']),
                           :title => d['value']['title'],
                           :date => date
                         }
    end
  end
  erb :index
end

# available spaces
get '/:space' do
  slug = params[:space]
  space = db.view("documents/by_space?key=%22#{slug}%22")
  if (space && space['rows'].length > 0)
    @space = { :slug => space['rows'][0]['key'], :title => space['rows'][0]['value']['space'] }
    documents = db.view("documents/by_space?key=%22#{slug}%22")
    if documents
      @documents = []
      documents["rows"].each do |d|
        date_created = Date.parse(d['value']['date_created']).strftime("%d/%m/%Y %p") if d['value']['date_created']
        date_updated = Date.parse(d['value']['date_updated']).strftime("%d/%m/%Y %p") if d['value']['date_updated']
        @documents << { :slug => d['value']['slug'],
                        :title => d['value']['title'],
                        :tags => d['value']['tags'],
                        :date_created => date_created,
                        :date_updated => date_updated,
                        :author => d['value']['author']
                      }
      end
    end
    erb :space
  else
    status 404
    "Not Found"
  end
end

# view page
get '/:space/:slug' do
  space_slug = params[:space]
  slug = params[:slug]
  document = db.view("documents/by_slug?key=%22#{space_slug}/#{slug}%22")
  if (document && document["rows"].length > 0)
    document = document["rows"][0]["value"]
    @title = document["title"]
    @slug = document["slug"]
    @space = document["space"]
    @space_slug = slug(@space)
    @tags = document["tags"].join(", ") if document["tags"]
    @date_created = Date.parse(document['date_created']).strftime("%d/%m/%Y %p") if document['date_created']
    @date_updated = Date.parse(document['date_updated']).strftime("%d/%m/%Y %p") if document['date_updated']
    @author = document["author"]
    if params[:edit]
      @id = document["_id"]
      @revision = document["_rev"]
      @state = "Existing"
      @content = document["content"]
      erb :form
    else
      @content = add_wiki_links(Maruku.new(document["content"]).to_html, @space_slug)
      erb :document
    end
  else
    @title = slug.capitalize
    @slug = slug
    @space = space_slug.capitalize
    @state = "New"
    @author = "Ashley Richardson <ash@threeheadedmonkey.com>"
    erb :form
  end
end

post '/' do
  id = params[:id]
  unless id.chop.empty?
    document = db.get(id)
    #logger.info("Updating existing document")
    unless document
      status 404
      "Not Found"
    end
  else
    #logger.info("Creating new document")
    document = {}
    document[:date_created] = Time.new.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
  end
  revision = params[:revision]
  if document['_rev'] && document['_rev'] != revision
    status 409
    "Bad document version/revision"
  end
  # update content, tags, author, slug, dates
  document[:space] = params[:space]
  title = params[:title]
  document[:title] = title
  document[:slug] = params[:slug] || slug(title)
  document[:content] = params[:content]
  document[:author] = params[:author]
  document[:date_updated] = Time.new.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
  if params[:tags]
    document[:tags] = params[:tags].split(",") 
  else
    document[:tags] = []
  end
  # save content
  db.save_doc(document)
  #redirect to get
  redirect "/#{slug(document[:space])}/#{document[:slug]}"
end

private

def slug(title)
  title.gsub(/'+/,'').gsub(/[^\w\/]|[!\(\)\.]+/, ' ').strip.downcase.gsub(/\ +/, '-')
end

def add_wiki_links(content, space_slug)
  puts content
  puts "----"
  content.gsub!(/\{\{.+\}\}/) do |result|
    puts result
    result.gsub!(/\{\{/, '').gsub!(/\}\}/, '')
    puts result
    slug, title = result.include?("|") ? result.split('|') : [result, result]
    if (slug.include?("/"))
      space_slug, slug = slug.split('/')
    end
    url = "<a href=\"/#{space_slug}/#{slug}\">#{title}</a>"
    puts url
    url
  end
  content
end
