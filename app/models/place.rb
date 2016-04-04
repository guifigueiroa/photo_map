class Place
  attr_accessor :id, :formatted_address, :location, :address_components
  
  def initialize(params)
    @id = params[:_id].to_s
    
    unless params[:address_components].nil?
      @address_components = params[:address_components].map { |component| AddressComponent.new(component) }
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
    
    places.map do |place| 
      Place.new(place)
    end
  end
  
  def self.to_places(collection)
    collection.map { |place| Place.new(place) }
  end
  
  def self.get_address_components(sort=nil, offset=nil, limit=nil)
    q = Place.collection.find.aggregate([	{ :$project => { :address_components => 1, :formatted_address => 1, "geometry.geolocation" => 1  } }, { :$unwind => '$address_components' }])
    q.pipeline << {:$sort => sort} if !sort.nil?
    q.pipeline << {:$skip => offset} if !offset.nil?
    q.pipeline << {:$limit => limit} if !limit.nil?    
    return q
  end
  
  def self.get_country_names
    Place.collection.find.aggregate([ 
      { :$project => { "address_components.long_name" => 1, "address_components.types" => 1 }}, 
      { :$unwind => '$address_components' }, 
      { :$match => { "address_components.types" => "country" } }, 
      { :$group => { :_id => "$address_components.long_name" } } ]).to_a.map {|h| h[:_id]}
  end
  
  def self.find_ids_by_country_code(country_code)
    Place.collection.find.aggregate([ 
      { :$match => { "address_components.types" => "country", "address_components.short_name" => country_code } },
      { :$project => { :_id => 1} }
      ]).map {|doc| doc[:_id].to_s}
  end
  
  def self.create_indexes 
    collection.indexes.create_one({ "geometry.geolocation" => "2dsphere" })
  end
  
  def self.remove_indexes
    Place.collection.indexes.drop_all
  end
  
  def self.near(point, max_meters=nil)
    collection.find( "geometry.geolocation" =>
        { :$near => {
          :$geometry => point.to_hash,
          :$maxDistance => max_meters}
        }
     )
  end
  
  def near(max_meters=nil)
    Place.to_places(self.class.near(@location, max_meters))
  end
  
  def destroy
    self.class.collection.find(_id: BSON::ObjectId(@id)).delete_one
  end
end