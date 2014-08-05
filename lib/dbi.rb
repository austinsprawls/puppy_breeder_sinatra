require 'pg'

module PuppyMill
  class DBI
    # this initialize method is only ever run once. make sure you
    # update your `dbname`. here it is petbreeder.
    def initialize
      @db = PG.connect(host: 'localhost', dbname: 'puppybreeder')
      build_tables
    end

    # these methods create the tables in your db if they
    # dont already exist
    def build_tables
      @db.exec(%q[
        CREATE TABLE IF NOT EXISTS breeds(
          id serial NOT NULL PRIMARY KEY,
          breed varchar(30),
          price integer
        )])

      @db.exec(%q[
        CREATE TABLE IF NOT EXISTS puppies(
          id serial NOT NULL PRIMARY KEY,
          breed varchar(30),
          name varchar(30),
          age integer,
          created_at timestamp NOT NULL DEFAULT current_timestamp
        )])

      @db.exec(%q[
        CREATE TABLE IF NOT EXISTS requests(
          id serial NOT NULL PRIMARY KEY,
          breed text,
          status text,
          created_at timestamp NOT NULL DEFAULT current_timestamp
        )])
    end


    #
    # Method to create a breed record
    #
    def create_breed(breed, price)
      @db.exec(%q[
        INSERT INTO breeds (breed, price)
        VALUES ($1, $2);
      ], [breed, price])
    end

    def get_breed_price(breed)
      response = @db.exec("SELECT price FROM breeds WHERE breed = '#{breed}'")
      return 'Unknown' if response.first.nil?
      response.first["price"]
    end

    def save_puppy(breed,name, age)
      @db.exec(%q[
        INSERT INTO puppies (breed,name,age)
        VALUES ($1, $2, $3);
        ], [breed,name,age])
      modify_hold_orders(breed)
    end

    def get_all_pups
      rows = @db.exec("SELECT id, breed, name, age FROM puppies")
      rows.map { |pup| build_puppy(pup) }
    end

    def build_puppy(pup)
      PuppyMill::Puppy.new(name: pup["name"], id: pup["id"], age: pup["age"], breed: pup["breed"])
    end

    def breed_available?(breed)
      get_all_pups.any? {|pup| pup.breed == breed }
    end

    def save_request(breed, status)
      @db.exec(%q[
        INSERT INTO requests (breed, status)
        VALUES ($1, $2);
        ], [breed, status])
    end

    def get_all_hold_requests
      rows = @db.exec("SELECT id, breed, status FROM requests WHERE status = 'hold'")
      rows.map {|request| build_request(request)}
    end

    def get_all_pending_requests
      rows = @db.exec("SELECT id, breed, status FROM requests WHERE status = 'pending'")
      rows.map {|request| build_request(request)}
    end

    def get_all_accepted_requests
      rows = @db.exec("SELECT * FROM requests WHERE status='accepted'")
      rows.map {|request| build_request(request)}
    end

    def update_request_status(new_status, id)
      @db.exec("UPDATE requests SET status = '#{new_status}' WHERE id= '#{id}'")

    end

    def modify_hold_orders(breed)
      modified = @db.exec("UPDATE requests SET status = 'pending' WHERE breed = '#{breed}'")
      get_all_pending_requests.each {|request| request.pend!}
      modified
    end

    def build_request(request)
      PuppyMill::PurchaseOrder.new(breed: request["breed"], id: request["id"], status: request["status"])
    end
  end

  # singleton creation
  def self.dbi
    @__db_instance ||= DBI.new
  end
end
