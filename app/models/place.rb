class Place
  attr_accessor :id, :formatted_address, :location, :address_components
  
  def initialize(params)
    @id = params[:_id].to_s
    
    @address_components = []
    params[:address_components].each do |component|
      @address_components << AddressComponent.new(component)
    end
    
    @formatted_address = params[:formatted_address]
    @location = params[:geometry][:geolocation]
  end
  
  def self.mongo_client
    Mongoid::Clients.default
  end
  
  def self.collection
    mongo_client[:places]
  end
  
  def self.load_all(file)
    hash = JSON.parse(file.read)
    places = Place.collection
    places.insert_many(hash)
  end
end