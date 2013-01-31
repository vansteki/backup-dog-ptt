require 'mongo'
include Mongo

def mongo_ini(id, pass)
	@client = MongoClient.new('linus.mongohq.com', 10054)
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

def db_insert_data(arr)
	begin
		arr.each{  |m|
			@coll.insert({
				"date"=> m['date'],
				"createTime"=>	m['createTime'], 
				"head"=>	m['head'], 
				"author"=>	m['author'],
				"title"=>	m['title'],
				"all"=>	m['all']
			})
		}
	rescue
		puts "\n nothing to db! \n"
	end
end