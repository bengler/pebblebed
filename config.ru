require 'bundler'
Bundler.require

use Pebbles::PowProxy
run lambda { |env| [200, {"Content-Type" => "text/html"}, ["Have at some pebbles!"]] }