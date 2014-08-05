require 'sinatra'
require_relative 'lib/puppy.rb'
require_relative 'lib/dbi.rb'

set :bind, "0.0.0.0"

get '/' do
  erb :index
end

get '/add_puppy' do
  erb :puppies
end

get '/puppies/:id' do
  @id = params[:id]
  # pup = PuppyMill::Puppies.pups_array.select {|pup| pup.id == @id}.pop
  pup = PuppyMill.dbi.get_all_pups.select {|pup| pup.id == @id}.pop
  @name = pup.name
  @breed = pup.breed
  @age = pup.age
  erb :show_pup
end

get '/puppies' do
  # @all_pups = PuppyMill::Puppies.all_pups
  @all_pups = PuppyMill.dbi.get_all_pups
  erb :puppies
end

post '/puppies' do
  breed = params[:breed]
  age = params[:age]
  @name = params[:name]
  PuppyMill.dbi.save_puppy(breed, @name, age)
  PuppyMill.dbi.modify_hold_orders(breed)
  # new_pup = PuppyMill::Puppy.new(age: age, breed: breed, name: @name)
  # PuppyMill::Puppies.add_pup(new_pup)
  # @all_pups = PuppyMill::Puppies.all_pups
  @all_pups = PuppyMill.dbi.get_all_pups
  erb :puppies
end

post '/breeds' do
  breed = params[:breed]
  @price = params[:price].to_i
  PuppyMill.dbi.create_breed(breed, @price)
  @all_pups = PuppyMill.dbi.get_all_pups
  erb :puppies
end

# get '/create_purchase_order' do
#   erb :purchase_orders
# end

get '/purchase_orders' do
  # @all_pending = PuppyMill::PurchaseOrders.view_all_pending_orders
  @all_pending = PuppyMill.dbi.get_all_pending_requests
  # @accepted_orders = PuppyMill::PurchaseOrders.view_all_accepted_orders
  @accepted_orders = PuppyMill.dbi.get_all_accepted_requests
  erb :purchase_orders
end

get '/purchase_orders/:id' do
  # @po = PuppyMill::PurchaseOrders.view_all_pending_orders.select {|po| po.id == params[:id].to_i}.pop
  @po = PuppyMill.dbi.get_all_pending_requests.select {|po| po.id == params[:id]}.pop
  # @customer_name = @po.customer_name
  @breed = @po.breed
  @status = @po.status
  @id = @po.id
  erb :show_po
end

post '/purchase_orders' do
  # customer_name = params[:customer_name]
  breed = params[:breed]
  # new_po = PuppyMill::PurchaseOrder.new(breed: breed)
  # PuppyMill::PurchaseOrders.add_order(new_po)
  @status = PuppyMill.dbi.breed_available?(breed) ? 'pending' : 'hold'
  PuppyMill.dbi.save_request(breed, @status)
  # @accepted_orders = PuppyMill::PurchaseOrders.view_all_accepted_orders
  @accepted_orders = PuppyMill.dbi.get_all_accepted_requests
  # @all_pending = PuppyMill::PurchaseOrders.view_all_pending_orders
  @all_pending = PuppyMill.dbi.get_all_pending_requests
  erb :purchase_orders
end

post '/purchase_orders/:id' do
  # @po = PuppyMill::PurchaseOrders.view_all_pending_orders.select {|po| po.id == params[:id].to_i}.pop
  # @customer_name = @po.customer_name
  @po = PuppyMill.dbi.get_all_pending_requests.select {|po| po.id == params[:id]}.pop
  @breed = @po.breed
  @status = params[:status]
  if @status == 'accepted'
    @po.accept!
  elsif @status == 'denied'
    @po.deny!
  elsif @status == 'hold'
    @po.hold!
  else
    @po.pend!
  end
  PuppyMill.dbi.update_request_status(@status, @po.id)
  # @accepted_orders = PuppyMill.dbi.get_all_accepted_requests
  # @all_pending = PuppyMill::PurchaseOrders.view_all_pending_orders
  # @all_pending = PuppyMill.dbi.get_all_pending_requests
  # erb :purchase_orders
  redirect to '/purchase_orders'
end
