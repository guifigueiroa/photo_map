class Place
  attr_accessor :id, :formatted_address, :location, :address_components
  
  def initialize(params)
    @id = params[:_id].to_s
    
    @address_components = []
    params[:address_components].each do |component|
      @address_components << AddressComponent.new(component)
    end
    
    @formatted_address = params[:formatted_address]
    @location = Point.new(params[:geometry][:geolocation])
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
  
  def self.find_by_short_name(short_name)
    collection.find({"address_components.short_name" => short_name})
  end
  
  def self.find(id)
    id = BSON::ObjectId.from_string(id)
    place = collection.find(_id: id).first
    Place.new(place) if !place.nil?
  end
  
  def self.all(offset=0, limit=nil)
    if limit.nil?
      places = collection.find.skip(offset)
    else
      places = collection.find.skip(offset).limit(limit)  
    end
    
    objs = []
    places.each do |place| 
      objs << Place.new(place)
    end
    objs
  end
  
  def self.to_places(collection)
    places = []
    collection.each do |place| 
      places << Place.new(place)
    end
    places
  end
  
  def destroy
    self.class.collection.find(_id: BSON::ObjectId(@id)).delete_one
  end
end