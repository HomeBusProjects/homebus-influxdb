require 'homebus'

require 'homebus-influxdb/version'

class HomebusInfluxdb::Options < Homebus::Options
  def app_options(op)
  end

  def banner
    'Homebus Influxdb'
  end

  def version
    HomebusInfluxdb::VERSION
  end

  def name
    'homebus-influxdb'
  end
end
