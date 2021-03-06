require 'rubygems'
require 'mongo'
include Mongo

def mongo_ini(id, pass)
	@client = MongoClient.new('localhost', 27017)
	@db     = @client['']
	@coll   = @db['']
	auth = @db.authenticate(id, pass)
end

def this_year()
	time = Time.new
	return time.strftime("%Y")
end

def remove_coll()
	@coll.remove
end

def mongo_insert_data(arr)
	begin
		arr.each{  |m|
			@coll.insert({
				"date"=> m['date'],
				"createTime"=>	m['createTime'], 
				"head"=>	m['head'], 
				"author"=>	m['author'],
				"title"=>	m['title'],
				"full_article"=>	m['full_article']
			})
		}
	rescue
		puts "\n nothing to db! \n"
	end
end
