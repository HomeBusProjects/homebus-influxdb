require 'homebus'

class InfluxDBHomebusAppOptions < Homebus::Options
  def app_options(op)
  end

  def banner
    'Homebus Influxdb'
  end

  def version
    '0.0.1'
  end

  def name
    'homebus-influxdb'
  end
end
