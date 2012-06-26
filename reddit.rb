%w{sinatra data_mapper haml sinatra/reloader}.each { |lib| require lib}
DataMapper::setup(:default,"sqlite3://#{Dir.pwd}/example.db")
class Link
  include DataMapper::Resource; attr_accessor :score
  [[:id, Serial],[:title, String],[:url, Text],[:score, Integer],[:points, Integer, :default => 0],[:created_at, Time]].each { |args| property *args; }
  def calculate_score; self.score = ((self.points-1) / (((Time.now - self.created_at) / 3600) +2)**1.8).real end
  def self.all_sorted_desc; self.all.each { |item| item.calculate_score }.sort { |a,b| a.score <=> b.score }.reverse end
end
DataMapper.finalize.auto_upgrade!
['/', '/hot', '/:id/vote/:type'].each { |path| path == '/' ? (((get (path) {@links = Link.all :order => :id.desc; haml :index}) && (post (path) {l, l.title, l.url, l.created_at = Link.new, params[:title], params[:url], Time.now; l.save!; redirect back}))) : path == '/hot' ? (get (path) { @links = Link.all_sorted_desc; haml :index}) : (put (path) {l = Link.get params[:id]; l.points += params[:type].to_i; l.save; redirect back})}

__END__

@@ layout
%html
	%head
		%link(rel="stylesheet" href="/css/bootstrap.css")
		%link(rel="stylesheet" href="/css/style.css")
	%body
		.container
			#main
				.title Learn Sinatra
				.options	
					%a{:href => ('/')} New 
					| 
					%a{:href => ('/hot')} Hot
				= yield

@@ index
#links-list	
	-@links.each do |l|	
		.row
			.span3
				%span.span
					%form{:action => "#{l.id}/vote/1", :method => "post"}
						%input{:type => "hidden", :name => "_method", :value => "put"}
						%input{:type => "submit", :value => "⇡"}
				%span.points
					#{l.points}
				%span.span
					%form{:action => "#{l.id}/vote/-1", :method => "post"}
						%input{:type => "hidden", :name => "_method", :value=> "put"}
						%input{:type => "submit", :value => "⇣"}				
			.span6
				%span.link-title
					%h3
						%a{:href => (l.url)} #{l.title}
#add-link
	%form{:action => "/", :method => "post"}
		%input{:type => "text", :name => "title", :placeholder => "Title"}
		%input{:type => "text", :name => "url", :placeholder => "Url"}
		%input{:type => "submit", :value => "Submit"}	
