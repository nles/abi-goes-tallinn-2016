require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'json'

set :bind, '0.0.0.0'
set :port, 3025 
set :environment, :production

# Handle GET-request (Show the upload form)
post "/payload" do
  request.body.rewind
  payload_body = request.body.read
  verify_signature(payload_body)
  # we good, lets do it!
  system('cd .. && git pull')
end

def verify_signature(payload_body)
  secret = "da661468c44ff8d338beefe51805806fcfaf765c"
  signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), secret, payload_body)
  return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
end
