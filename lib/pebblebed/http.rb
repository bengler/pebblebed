# A wrapper for all low level http client stuff

require 'uri'
require 'curl'
require 'yajl'
require 'queryparams'
require 'nokogiri'
require 'pathbuilder'
require 'active_support'

module Pebblebed
  class HttpError < Exception; end

  class ClientError < HttpError; end

  class BadRequest < ClientError; end 

  module Http
    class CurlResult
      def initialize(curl_result)
        @curl_result = curl_result
      end

      def status
        @curl_result.response_code
      end

      def url
        @curl_result.url
      end

      def body
        @curl_result.body_str
      end
    end


    def self.get(url = nil, params = nil, &block)
      url, params = url_and_params_from_args(url, params, &block)      
      handle_curl_response(Curl::Easy.perform(url_with_params(url, params)))
    end

    def self.post(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)      
      handle_curl_response(Curl::Easy.http_post(url, *(QueryParams.encode(params).split('&'))))
    end

    def self.delete(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)      
      handle_curl_response(Curl::Easy.http_delete(url_with_params(url, params)))
    end

    private

    def self.sinatra_error(html_text)
      doc = Nokogiri::HTML(html_text)
      @@sinatra_embed_css + doc.css('script,body').to_html
    end

    def self.handle_http_errors(result)
      if result.status >= 400
        errmsg = "Service request to <a href=\"#{result.url}\">#{result.url}</a> failed with the following error:</pre>"
        errmsg << "<div id=\"sinatra_error\">#{sinatra_error(result.body)}</div><pre>"
        raise HttpError, ActiveSupport::SafeBuffer.new(errmsg) # same as errmsg.html_safe in rails
      end
      result
    end

    def self.handle_curl_response(curl_response)      
      handle_http_errors(CurlResult.new(curl_response))
    end

    def self.url_with_params(url, params)
      url.query = QueryParams.encode(params || {})
      url.to_s
    end

    def self.url_and_params_from_args(url, params = nil, &block)
      if block_given?
        pathbuilder = PathBuilder.new.send(:instance_eval, &block)
        url = url.dup
        url.path = url.path.chomp("/")+pathbuilder.path
        (params ||= {}).merge!(pathbuilder.params)
      end
      [url, params]
    end

    # todo: find a better place for this (where could that be?)
    @@sinatra_embed_css = <<CSS
      <style type="text/css">
        #sinatra_error *{border:0;outline:0;margin:0;padding:0;line-height:100%;}
        #sinatra_error div.clear{clear:both}
        #sinatra_error body{background:#EEE;font-family:'Lucida Grande', 'Lucida Sans Unicode', Garuda;margin:0;padding:0}
        #sinatra_error code{font-family:'Lucida Console', monospace;font-size:12px}
        #sinatra_error li{height:18px}
        #sinatra_error ul{list-style:none;margin:0;padding:0}
        #sinatra_error ol:hover{cursor:pointer}
        #sinatra_error ol li{white-space:pre}
        #sinatra_error #explanation{font-size:12px;color:#666;margin:20px 0 0 100px}
        #sinatra_error #wrap{width:1000px;background:#FFF;border-color: #777 #ddd #ddd #777; border-width:2px;border-style:solid;;margin:0 auto;padding:30px 50px 20px}
        #sinatra_error #header{margin:0 auto 25px}
        #sinatra_error #header img{float:left}
        #sinatra_error #header #summary{float:left;width:660px;font-family:'Lucida Grande', 'Lucida Sans Unicode';margin:12px 0 0 20px}
        #sinatra_error h1{font-size:36px;color:#981919;margin:0}
        #sinatra_error h2{font-size:22px;color:#333;margin:0}
        #sinatra_error #header ul{font-size:12px;color:#666;margin:0}
        #sinatra_error #header ul li strong{color:#444}
        #sinatra_error #header ul li{display:inline;padding:0 10px}
        #sinatra_error #header ul li.first{padding-left:0}
        #sinatra_error #header ul li.last{border:0;padding-right:0}
        #sinatra_error #backtrace,#sinatra_error #get,#sinatra_error #post,#sinatra_error #cookies,#sinatra_error #rack{width:980px;margin:0 auto 10px}
        #sinatra_error p#nav{float:right;font-size:14px}
        #sinatra_error a#expando{float:left;padding-left:5px;color:#666;font-size:14px;text-decoration:none;cursor:pointer}
        #sinatra_error a#expando:hover{text-decoration:underline}
        #sinatra_error h3{float:left;width:100px;margin-bottom:10px;color:#981919;font-size:14px;font-weight:700}
        #sinatra_error #nav a{color:#666;text-decoration:none;padding:0 5px}
        #backtrace li.frame-info{background:#f7f7f7;padding-left:10px;font-size:12px;color:#333}
        #sinatra_error #backtrace ul{list-style-position:outside;border:1px solid #E9E9E9;border-bottom:0}
        #sinatra_error #backtrace ol{width:920px;margin-left:50px;font:10px 'Lucida Console', monospace;color:#666}
        #sinatra_error #backtrace ol li{border:0;border-left:1px solid #E9E9E9;padding:2px 0}
        #sinatra_error #backtrace ol code{font-size:10px;color:#555;padding-left:5px}
        #sinatra_error #backtrace-ul li{border-bottom:1px solid #E9E9E9;height:auto;padding:3px 0}
        #sinatra_error #backtrace-ul .code{padding:6px 0 4px}
        #sinatra_error p.no-data{padding-top:2px;font-size:12px;color:#666}
        #sinatra_error table.req{width:980px;text-align:left;font-size:12px;color:#666;border-spacing:0;border:1px solid #EEE;border-bottom:0;border-left:0;clear:both;padding:0}
        #sinatra_error table.req tr th{font-weight:700;background:#F7F7F7;border-bottom:1px solid #EEE;border-left:1px solid #EEE;padding:2px 10px}
        #sinatra_error table.req tr td{border-bottom:1px solid #EEE;border-left:1px solid #EEE;padding:2px 20px 2px 10px}
        #sinatra_error table td.code{width:750px}
        #sinatra_error table td.code div{width:750px;overflow:hidden}
        #sinatra_error #backtrace.condensed .system,#sinatra_error #backtrace.condensed .framework,#sinatra_error .pre-context,#sinatra_error .post-context{display:none}
      </style>
CSS
  end
end