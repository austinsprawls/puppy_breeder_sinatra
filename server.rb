require 'sinatra'
require_relative 'lib/puppy.rb'

get '/' do
  erb :index
end

get '/add_puppy' do
  erb :puppies
end

get '/puppies/:id' do
  @id = params[:id].to_i
  pup = PuppyMill::Puppies.pups_array.select {|pup| pup.id == @id}.pop
  @name = pup.name
  @breed = pup.breed
  @age = pup.age
  erb :show_pup
end

get '/puppies' do
  @all_pups = PuppyMill::Puppies.all_pups
  erb :puppies
end

post '/puppies' do
  breed = params[:breed]
  age = params[:age]
  @name = params[:name]
  new_pup = PuppyMill::Puppy.new(age: age, breed: breed, name: @name)
  PuppyMill::Puppies.add_pup(new_pup)
  @all_pups = PuppyMill::Puppies.all_pups
  erb :puppies
end

get '/create_purchase_order' do
  erb :purchase_orders
end

get '/purchase_orders' do
  @all_pending = PuppyMill::PurchaseOrders.view_all_pending_orders
  @accepted_orders = PuppyMill::PurchaseOrders.view_all_accepted_orders
  erb :purchase_orders
end

get '/purchase_orders/:id' do
  @po = PuppyMill::PurchaseOrders.view_all_pending_orders.select {|po| po.id == params[:id].to_i}.pop
  @customer_name = @po.customer_name
  @breed = @po.breed
  @status = @po.status
  @id = @po.id
  erb :show_po
end

post '/purchase_orders' do
  customer_name = params[:customer_name]
  breed = params[:breed]
  new_po = PuppyMill::PurchaseOrder.new(customer_name: customer_name, breed: breed)
  PuppyMill::PurchaseOrders.add_order(new_po)
  @accepted_orders = PuppyMill::PurchaseOrders.view_all_accepted_orders
  @all_pending = PuppyMill::PurchaseOrders.view_all_pending_orders
  erb :purchase_orders
end

post '/purchase_orders/:id' do
  @po = PuppyMill::PurchaseOrders.view_all_pending_orders.select {|po| po.id == params[:id].to_i}.pop
  @customer_name = @po.customer_name
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
  erb :show_po
end
