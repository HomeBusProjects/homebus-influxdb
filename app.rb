# coding: utf-8
require 'homebus'

require 'dotenv'
require 'influxdb-client'
require 'influxdb-client-apis'

require 'time'

class InfluxDBHomebusApp < Homebus::App
  DDCS = [
    'org.homebus.experimental.3dprinter',
    'org.homebus.experimental.3dprinter-completed-job',
    'org.pdxhackerspace.experimental.access',
    'org.homebus.experimental.air-quality-sensor',
    'org.homebus.experimental.air-sensor',
    'org.homebus.experimental.alert',
    'org.homebus.experimental.aqi-pm25',
    'org.homebus.experimental.aqi-o3',
    'org.homebus.experimental.ccs811-sensor',
    'org.homebus.experimental.ch4-sensor',
    'org.homebus.experimental.co-sensor',
    'org.homebus.experimental.co2-sensor',
    'org.homebus.experimental.contact-sensor',
    'org.homebus.experimental.covid-cases',
    'org.homebus.experimental.covid-hospitalizations',
    'org.homebus.experimental.covid-vaccinations',
    'org.homebus.experimental.diagnostic',
    'org.homebus.experimental.h2co-sensor',
    'org.homebus.experimental.h2s-sensor',
    'org.homebus.experimental.homebus.devices',
    'org.homebus.experimental.image',
    'org.homebus.experimental.license',
    'org.homebus.experimental.light-sensor',
    'org.homebus.experimental.location',
    'org.homebus.experimental.lunar-phase',
    'org.homebus.experimental.my-ip',
    'org.homebus.experimental.nh3-sensor',
    'org.homebus.experimental.no2-sensor',
    'org.homebus.experimental.noise-sensor',
    'org.homebus.experimental.network-active-hosts',
    'org.homebus.experimental.network-bandwidth',
    'org.homebus.experimental.o2-sensor',
    'org.homebus.experimental.o3-sensor',
    'org.homebus.experimental.occupancy-sensor',
    'org.homebus.experimental.origin',
    'org.homebus.experimental.ph-sensor',
    'org.homebus.experimental.radon-sensor',
    'org.homebus.experimental.radiation-sensor',
    'org.homebus.experimental.server-status',
    'org.homebus.experimental.so2-sensor',
    'org.homebus.experimental.soil-sensor',
    'org.homebus.experimental.solar-clock',
    'org.homebus.experimental.switch',
    'org.homebus.experimental.system',
    'org.homebus.experimental.system.filesystem',
    'org.homebus.experimental.system.memory',
    'org.homebus.experimental.system.load',
    'org.homebus.experimental.temperature-sensor',
    'org.homebus.experimental.uninterruptible-power-supply',
    'org.homebus.experimental.uv-light-sensor',
    'org.homebus.experimental.voc-sensor',
    'org.homebus.experimental.weather',
    'org.homebus.experimental.weather-forecast',
    "com.romkey.test.dfrobot-invalid"
  ]

  def initialize(options)
    @options = options
    super
  end

  def setup!
    Dotenv.load('.env')

    @image_expiration_interval = 86400
    @influxdb_organization = ENV['INFLUXDB_ORGANIZATION']
    @client = InfluxDB2::Client.new ENV['INFLUXDB_URL'],
                                    ENV['INFLUXDB_TOKEN'],
                                    org: @influxdb_organization,
                                    bucket: ENV['INFLUXDB_BUCKET'],
                                    use_ssl: false,
                                    precision: InfluxDB2::WritePrecision::SECOND

    @write_api = @client.create_write_api

    @device = Homebus::Device.new name: 'Homebus InfluxDB recorder',
                                  manufacturer: 'Homebus',
                                  model: 'InfluxDB',
                                  serial_number: ENV['INFLUXDB_URL']

    @ddcs = DDCS
    @device_name_map = {}
  end

  def work!
    DDCS.each do |ddc|
      @device.provision.broker.subscribe!(ddc)
    end

    listen!
  end

  def receive!(msg)
    if msg[:ddc] == 'org.homebus.experimental.homebus.devices'
      _process_devices(msg[:payload])
      return
    end

    # we don't currently store arrays
    if msg[:payload].class != Hash
      return
    end

    data = InfluxDB2::Point.new(name: msg[:ddc])
                                  .add_tag('source', msg[:source])
                                  .time(Time.at(msg[:timestamp]), InfluxDB2::WritePrecision::SECOND)

    name = @device_name_map[msg[:source]]
    if name
      data.add_tag('name', @device_name_map[msg[:source]])
    end

    if @options[:verbose]
      puts "PAYLOAD from #{msg[:source]} - #{msg[:ddc]} at #{Time.at(msg[:timestamp]).to_s}"
      pp msg[:payload]
    end

    msg[:payload].each do |key, value|
      if value.class == Array || value.class == Hash
        return
      end

      if value.class == Integer || key == :pressure
        value = value.to_f
      end

      if @options[:verbose]
        puts "key #{key} value #{value} class #{value.class}"
      end

      data.add_field(key, value)
    end

    begin
      @write_api.write(data: data)
    rescue => error
      if @options[:verbose]
        puts "error writing data: #{error.message}"
      end
    end
  end

  def _process_devices(msg)
    devices = {}
    publish_ddcs = []
    msg[:devices].each do |device|
      publish_ddcs += device[:publishes]
      devices[device[:id]] = device[:name]
    end

    @ddcs = publish_ddcs.sort.uniq
    @device_name_map = devices

    File.write('network.json', JSON.pretty_generate({ devices: devices, published_ddcs: @ddcs}))
  end

  def name
    'Homebus InfluxDB recorder'
  end

  def consumes
    DDCS
  end

  def publishes
    []
  end

  def devices
    [ @device ]
  end
end
