class Point
  attr_accessor :latitude, :longitude
  
  def initialize(params)
    @longitude = params[:lng] || params[:coordinates][0]
    @latitude = params[:lat] || params[:coordinates][1]
    @type = params[:type] || "Point"
  end
  
  def to_hash
    {type: @type, coordinates: [ @longitude, @latitude ]}
  end
end