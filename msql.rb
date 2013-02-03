require 'mysql'

db = Mysql.init  
db.options(Mysql::SET_CHARSET_NAME,"utf8")  
$con = db.real_connect('localhost', '[ID]', '[PASS]', '[DB]')

def insert_data(arr)
	pp arr
	arr.each{  |m| 		
		ready = $con.prepare('INSERT INTO gm(author,title,date,head,full_article ,createTime) VALUES (?,?,?,?,?,?)')
		ready.execute m['author'], m['title'], m['date'], m['head'] ,m['full_article'] ,m['createTime']
	}
	puts $con.character_set_name
end