class Photo
  attr_accessor :id, :location
  attr_writer :contents
  
  def initialize(params=nil)
    unless params.nil?
      @id = params[:_id].to_s
      @location = Point.new(params[:metadata][:location])
    end
  end
  
  def save
    if self.persisted?
      #nothing for now
    else
      description = {}
      description[:filename] = @contents.to_s
      description[:content_type] = "image/jpeg"
      description[:metadata] = {}
      gps = EXIFR::JPEG.new(@contents).gps
      @contents.rewind
      @location = Point.new(lat: gps.latitude, lng: gps.longitude)
      description[:metadata][:location] = @location.to_hash 
      #description[:metadata][:place] = BSON::ObjectId.from_string(@place.id.to_s) if !@place.nil?
      
      grid_file = Mongo::Grid::File.new(@contents.read, description)
      @id=self.class.mongo_client.database.fs.insert_one(grid_file).to_s
    end
  end
  
  def persisted?
    !@id.nil?
  end
  
  def contents
    result = self.class.mongo_client.database.fs.find_one(_id: BSON::ObjectId.from_string(@id))
    if result
      buffer = ""
      result.chunks.reduce([]) do |x,chunk|
        buffer << chunk.data.data
      end
      return buffer
    end
  end
  
  def destroy
    self.class.mongo_client.database.fs.find(_id: BSON::ObjectId.from_string(@id)).delete_one
  end
  
  def self.mongo_client
    Mongoid::Clients.default
  end
  
  def self.all(offset = 0, limit = nil)
    result = mongo_client.database.fs.find.skip(offset)
    result = result.limit(limit) if !limit.nil?
    result.map {|doc| Photo.new(doc)}
  end
  
  def self.find(id)
    f = mongo_client.database.fs.find(_id: BSON::ObjectId.from_string(id.to_s)).first
    Photo.new(f) unless f.nil?
  end
end