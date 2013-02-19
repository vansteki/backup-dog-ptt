$DIR = File.expand_path(File.dirname(__FILE__)) + '/'
require 'rubygems'
require 'gmail'
require 'base64'
require 'json'
require 'pp'
require 'iconv'
require $DIR + 'msql.rb' #if run by crontab, use full path
require $DIR + 'mhq.rb' #if run by crontab, use full path

gmail_username = ''
gmail_password = ''
mongo_ini('', '')
$json_opt_path = $DIR + 'mailer.log'

def convert_month(month)
	$m =  month
	case $m
	when 'Jan'
		return '1'
	when 'Feb'
		return '2'
	when 'Mar'
		return '3'
	when 'Apr'
		return '4'
	when 'May'
		return '5'
	when 'Jun'
		return '6'
	when 'Jul'
		return '7'
	when 'Aug'
		return '8'
	when 'Sep'
		return '9'
	when 'Oct'
		return '10'
	when 'Nov'
		return '11'
	when 'Dec'
		return '12'
	else
		return 0
	end
end

def make_list(s, cont_que)
	date = nil
	s.scan(/(作者:\s+(.*)\s+\(.*\).*\s*標題:\s+(.*\S)\s+時間:\s+\w+\s+(\w+)\s+(\d+).*(\d\d\d\d))\s*((.|\n)*)/){
		|head, author, title, month, day, year, full_article|
		month = convert_month(month)
		date = "#{year}-#{month}-#{day}"
		cont_que.push("head"=>head, "author"=>author, "title"=>title, "date"=>date, "full_article"=>full_article, "createTime"=>$createTime) #, "AID"=>aid
	}
	puts "\n article_info parse done\n"
	pp cont_que
end

def day_add_zero(data)
	puts data.size
end

def big5_2_utf8(data)
	begin
		ic = Iconv.new("utf-8//IGNORE","big5")
		return ic.iconv(data)
	rescue
		return 'big5_2_utf8 error'
		puts "\n big5_2_utf8() error\n"
	end
end

def clean_ansi_color(s)
	s.gsub!(/\[\d+;\d*m|\[m|\[\d*m|\[\w+m/, '')
end

def clean_utf8_space(s)
	s.to_s.gsub!(/\\u001b/, '')
end

def add_br(s)
	s.gsub!(/\\n/, "\/n")
end

def now_time()
	time = Time.new
	return time.strftime("%Y-%m-%d %H:%M:%S")
end

def today()
	time = Time.new
	return time.strftime("%Y-%m-%d")
end

def log(log, file_name="index.html")
	File.open("#{file_name}","w+") do |f| f.puts log end
end

def dump_json(arr)
	#begin
		json = JSON.generate(arr)
		pp arr
		res = clean_utf8_space(add_br(json))
		#puts JSON.pretty_generate(arr)
		log(res, $json_opt_path)
		return JSON.parse(res)
	#rescue
	#	puts "\n nothing to dump! \n"
	#end
end

$createTime = now_time()
Gmail.connect(gmail_username, gmail_password) do |gmail|
	cont_que = []
	cont = []
	if gmail.logged_in?
		puts "login! \n"
	end
	puts "work date is #{today()}"

	gmail.inbox.emails(:unread, :before => Date.parse(today()), :from => "*.bbs@ptt.cc").each do |email|
		puts email.message.to_s
		log(email.message.to_s,"debug.log")
		cte = email.message.to_s.scan(/Content-Transfer-Encoding:\s*(.*)/).to_s
		if cte == "quoted-printable\r"
			match = email.message.to_s.scan(/(=A7@=AA=CC:(.|\n)*)/)
			c = match.to_s.unpack "M"
			pp c
			cont = big5_2_utf8(clean_ansi_color(c.to_s))
			make_list(cont, cont_que)
		else
			match = email.message.to_s.scan(/(p0CqzDog(.|\n)*)|[a-zA-Z0-9+]{30,}/) #p0CqzDog "作者"(big5) encoding of base64 at article header
			if match.size == 0
				match = email.message.to_s.scan(/LS0tLS0t(.|\n)*/) #gmail 轉寄 gmail
			end
			cont = big5_2_utf8(clean_ansi_color(Base64.decode64(match.to_s)))
			make_list(cont, cont_que)
		end
		#email.unread!
	end

	arr = dump_json(cont_que)
	mongo_insert_data(arr)
	insert_data(arr)
end