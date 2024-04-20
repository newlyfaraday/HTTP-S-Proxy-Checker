require 'net/http'
require 'optparse'
require 'uri'

class Proxy_Auto
  def initialize
    @proxy_data = Hash.new
    @threads = Array.new
    @url_file = nil
    @proxy_file = nil
    @url = 'http://example.com'
    @output = 'success.txt'
  end

  def optparser
    OptionParser.new do |parser|
      parser.on("-p", "--proxy-list PROXY_LIST") { |proxy_file| @proxy_file = proxy_file }
    end.parse!
  end

  def http_proxy(url, proxy_addr, proxy_port)
    begin
      uri = URI.parse(url)

      proxy_http = Net::HTTP.Proxy(proxy_addr, proxy_port).new(uri.host, uri.port)
      proxy_http.use_ssl = (uri.scheme == 'https')

      proxy_http.open_timeout = 3
      proxy_http.read_timeout = 3

      request = Net::HTTP::Get.new(url)
      response = proxy_http.request(request)

      puts("URL: #{url}\nResponse Code: #{response.code}\nProxy IP: #{proxy_addr}\nProxy Port: #{proxy_port}")
      puts("-" * 30)

      File.open(@output, 'a+') { |file| file.puts("#{proxy_addr}:#{proxy_port}") }
    rescue Exception
      puts("#{proxy_addr}:#{proxy_port} --> Error")
      return
    end
  end

  def proxy_processer(proxy_addr, proxy_port)
    @threads << Thread.new { http_proxy(@url, proxy_addr, proxy_port) }
  end

  def read_proxies
    proxies = File.readlines(@proxy_file)

    proxies.each do |proxy|
      proxy_ip, proxy_port = proxy.split(':')
      @proxy_data[proxy_ip.strip] = proxy_port.to_i
    end
  end

  def main
    optparser
    read_proxies

    @proxy_data.each do |proxy_addr, proxy_port|
      proxy_processer(proxy_addr, proxy_port)
    end

    @threads.each(&:join)
  end
end

auto_proxy = Proxy_Auto.new
auto_proxy.main
