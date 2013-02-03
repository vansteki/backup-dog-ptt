require 'rubygems'
require 'json'
require 'net/telnet'
require 'pp'
require 'iconv'

AnsiSetDisplayAttr = '\x1B\[(?>(?>(?>\d+;)*\d+)?)m'
WaitForInput =  '(?>\s+)(?>\x08+)'
AnsiEraseEOL = '\x1B\[K'
AnsiCursorHome = '\x1B\[(?>(?>\d+;\d+)?)H'
PressAnyKey = '\xAB\xF6\xA5\xF4\xB7\x4E\xC1\xE4\xC4\x7E\xC4\xF2'
Big5Code = '[\xA1-\xF9][\x40-\xF0]'
PressAnyKeyToContinue = "#{PressAnyKey}(?>\\s*)#{AnsiSetDisplayAttr}(?>(?:\\xA2\\x65)+)\s*#{AnsiSetDisplayAttr}"
PressAnyKeyToContinue2 = "\\[#{PressAnyKey}\\](?>\\s*)#{AnsiSetDisplayAttr}"
ArticleList = '\(b\)' + "#{AnsiSetDisplayAttr}" + '\xB6\x69\xAA\x4F\xB5\x65\xAD\xB1\s*' + "#{AnsiSetDisplayAttr}#{AnsiCursorHome}" # (b)進板畫面
Signature = '\xC3\xB1\xA6\x57\xC0\xC9\.(?>\d+).+' + "#{AnsiCursorHome}"
EmailBox = '[a-zA-Z0-9._%+-]+@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,4}'

#$json_opt_path = "/var/www/8GC/gc.html"

def connect(port, time_out, wait_time, host)
	tn = Net::Telnet.new(
	'Host'       => host,
	'Port'       => port,
	'Timeout'    => time_out,
	'Waittime'   => wait_time
	)
	return tn
end

def login(tn, id, password)
	tn.waitfor(/guest.+new(?>[^:]+):(?>\s*)#{AnsiSetDisplayAttr}#{WaitForInput}\Z/){ |s| print(s)}
	tn.cmd("String" => id, "Match" => /\xB1\x4B\xBD\x58:(?>\s*)\Z/){ |s| }
	tn.cmd("String" => password,
	"Match" => /#{PressAnyKeyToContinue}\Z/){ |s| print(s)}
	tn.print("\n")
end

#進入某板(等於從主畫面按's')
def jump_board(tn, board_name)

	# [呼叫器]
	tn.waitfor(/\[\xA9\x49\xA5\x73\xBE\xB9\]#{AnsiSetDisplayAttr}.+#{AnsiCursorHome}\Z/){ |s| }
	tn.print('s')
	tn.waitfor(/\):(?>\s*)#{AnsiSetDisplayAttr}(?>\s*)#{AnsiSetDisplayAttr}#{AnsiEraseEOL}#{AnsiCursorHome}\Z/){ |s| }
	lines = tn.cmd( "String" => board_name, "Match" => /(?>#{PressAnyKeyToContinue}|#{ArticleList})\Z/ ) do |s|
		print(s)
	end

	if not (/#{PressAnyKeyToContinue}\Z/ =~ lines)
		return lines
	end

	lines = tn.cmd("String" => "", "Match" => /#{ArticleList}\Z/) do |s|
		print(s)
	end
	return lines
end

def gsub_ansi_by_space(s)
	raise ArgumentError, "search_by_title() invalid title:" unless s.kind_of? String

	s.gsub!(/\x1B\[(?:(?>(?>(?>\d+;)*\d+)?)m|(?>(?>\d+;\d+)?)H|K)/) do |m|
		if m[m.size-1].chr == 'K'
			"\n"
		else
			" "
		end
	end
end

def search_by_title(tn, title)
	tn.print('?')
	tn.waitfor(/\xB7\x6A\xB4\x4D\xBC\xD0\xC3\x44:\s*#{AnsiCursorHome}#{AnsiSetDisplayAttr}\s+#{AnsiSetDisplayAttr}#{AnsiEraseEOL}#{AnsiCursorHome}\Z/){ |s| print(s) }
	result = tn.cmd( 'String' => title, 'Match' => /#{ArticleList}/){ |s| print(s) }
	return result
end

def goto_by_article_num(tn, num)
	tn.cmd("String" => (num.kind_of?(Integer) ? num.to_s : num), "Match" => /#{AnsiEraseEOL}#{AnsiCursorHome}\Z/){ |s| print(s) }
end

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

def mine_checker(data)
	return data.to_s.gsub(/"/, "'")
end

def search_by_hot(tn, number)
	tn.print('Z')
	tn.print("#{number}")
	tn.print("\n")
	bottom(tn)
end

def now_time()
	time = Time.new
	return now_time = time.strftime("%Y-%m-%d %H:%M:%S")
end

def log(log, file_name="index.html")
	File.open("#{file_name}","w+") do |f| f.puts log end
end

def leave_to_next_article(tn, enter='')
	tn.print('q')
	tn.print('k')
	if enter=='true'
		tn.print("\n")
	else
	end
end

def down(tn)
	tn.print("j")
end

def up(tn)
	tn.print("k")
end

def top(tn)
	tn.print("\e[1~")
end

def bottom(tn)
	tn.print("\e[4~")
end

def page_up(tn)
	tn.print("\e[5~")
end

def page_down(tn)
	tn.print("\e[6~")
end

def back_to_start_point(tn)
	bottom(tn)
	up(tn)
	up(tn)
	up(tn)
end

def big5_2_utf8(data)
	begin
		ic = Iconv.new("utf-8//IGNORE","big5")
		return ic.iconv(data.to_s)
	rescue
		return "big5 to utf8 faild!"
		puts "\n big5_2_utf8() error\n"
	end
end

def make_list(s='',aid='', full_article='')
	item = []
	article_info =[]
	main_content = []
	push_list = []
	date = nil

	s.scan(/\s+\xA7\x40\xAA\xCC\s+(.*)\s+\(.*\).*\s*\xBC\xD0\xC3\x44\s+(.+\S)\s+\xAE\xC9\xB6\xA1\s+\w+\s+(\w+)\s+(\d+).*(\d\d\d\d)/){
		|author, title, month, day, year|
		month = convert_month(month)
		date = "#{year}-#{month}-#{day}"
		article_info.push("author"=>big5_2_utf8(author), "title"=>big5_2_utf8(title), "date"=>date, "AID"=>aid)
	}
	puts "\narticle_info parse done\n"

	full_article.scan(/\(b\).*(\xA7\x40\xAA\xCC(.|\n)*.*From\:\s*\d*\.\d*\.\d*\.\d*)/){  |m|
		m = m.to_s.gsub(/\n/, "\\n")
		m = big5_2_utf8(m)
		main_content.push(m)
	}
	puts "\nmain_content parse done\n"

	full_article.scan(/.*From\:\s*\d*\.\d*\.\d*\.\d*((.|\n)*)/){ |p|
		#p = p.to_s.gsub(/\n\n/, '')
		p = p.to_s.gsub(/\n/, "\\n")
		p = mine_checker(p)
		p = big5_2_utf8(p)
		push_list.push(p)
	}
	puts "\npush_list parse done\n"

	$list.push("date"=>date, "ArticleInfo"=>article_info, "mainContent"=>main_content, "pushList"=>push_list)
	item.push("item" => $list)
	return item
end

def dump_json(arr)
	json = JSON.generate(arr)
	#puts json
	#puts JSON.pretty_generate(arr)
	puts "\n------ Count: #{arr.count}  at #{now_time()} ------\n"
	log(json, $json_opt_path)
	# db_insert_data(arr)
end

def scan_this_article(tn, article)
	full_article = article

	total_page = article.scan(/.+\xC2\x73\xC4\xFD\s+\xB2\xC4\s+\d+\/(\d+)/){
		|tp|
		puts "\n------ total page: #{tp} ------\n"
	}

	total_page[0].to_i.times do
		tn.print("\e[6~")
		tn.waitfor(/.*/){
			|s|
			print(s)
			full_article += s.to_s
		}
	end
	# full_article += art_que.to_s
	full_article = full_article.gsub(/\xC2\x73\xC4\xFD.*\xA6\xE6.*\xC2\xF7\xB6\x7D/,'')
	puts "\n scan_this_article() done! \n"
	return gsub_ansi_by_space(full_article)
end


def quick_loop_article(tn)
	list = []
	tn.print("\n")
	res = tn.waitfor(/.*(Gossiping).*/)
	article = gsub_ansi_by_space(res)
	res = make_list(article, list, '')
	puts "\n-------------read First article done-----------\n"
	#puts article
	leave_to_next_article(tn)

	for i in 2..5
		res = tn.waitfor(/.*(Gossiping).*/)
		article = gsub_ansi_by_space(res)
		res = make_list(article, list, '')
		puts "\n-------------read #{i} article done-----------\n"
		#puts article
		leave_to_next_article(tn)
	end
	return res
end

$aid_list =[]
def get_AID(tn)
	aid=''
	pop_view=''

	tn.print('Q')

	pop_view = tn.waitfor(/.*/){ |s| print(s) }

	pop_view.scan(/#(.*)\s*\(Gossiping\)/){|m|
		#print(m)
		puts "\n\n------ AID: #{m} ------\n\n"
		aid = m.to_s.gsub(/\[m/,'').delete(" ")
		$aid_list.push(aid)
		tn.print("\n")
	}

	if aid != ''
		return aid
	else
		tn.print('g')
		return 'noaid'
	end
end

$list = []
$loop_count = 1

def loop_each_article(tn)
	aid = get_AID(tn)

	if aid == 'noaid'
		up(tn)
		return loop_each_article(tn)
	end

	tn.print("\n")
	article = gsub_ansi_by_space(tn.waitfor(/.*(Gossiping).*/){ |s| print(s)})
	full_article = scan_this_article(tn, article)
	res = make_list(article, aid, full_article)
	puts "\n-------------read #{$loop_count} article done-----------\n"
	$loop_count +=1
	tn.print("q")
	up(tn)
	return res
end

def email_article(tn, email_box=nil)
	raise ArgumentError, "email_article() invalid telnet reference:" unless tn.kind_of? Net::Telnet
	if email_box != nil && ( !(email_box.kind_of? String) || !(/^#{EmailBox}$/ =~ email_box) )
		raise ArgumentError, "email_article() invalid email_box:"
	end
	begin

		tn.print("F")
		tn.print('n')
		tn.print("\n")
		result = tn.cmd("String" => email_box,
		"Match" => /(?>#{PressAnyKeyToContinue2}|#{ArticleList})\Z/
		){ |s| print(s) }

		if not (/#{PressAnyKeyToContinue2}\Z/ =~ result)
			puts "mail send!"
			return true # 轉寄成功!
		end

		tn.cmd("String" => "", "Match" => /#{ArticleList}\Z/) do |s|
			print(s)
		end
		return false # 轉寄失敗!
	rescue SystemCallError => e
		raise e, "email_article() system call:" + e.to_s()
	rescue TimeoutError => e
		raise e, "email_article() timeout:" + e.to_s()
	rescue SocketError => e
		raise e, "email_article() socket:" + e.to_s()
	rescue Exception => e
		raise e, "email_article() unknown:" + e.to_s()
	end
end

begin
	# if ARGV.size != 2 then
	# 	print("this.rb ID PASSWORD\n")
	# 	exit
	# end

	pttID = ''
	pttPASS = ''
	tn = connect(23, 10, 1, 'ptt.cc')
	start_time = now_time()
	login(tn, pttID, pttPASS)
	jump_board(tn, 'Gossiping')
	search_by_hot(tn, 50)
	for i in 1...21
		sleep(10)
		email_article(tn, "firedog977@gmail.com")
		sleep(2)
		up(tn)
	end
	puts "\n crawer send at #{start_time} , mission complete at #{now_time()}\n"

end

