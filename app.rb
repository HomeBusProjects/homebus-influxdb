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
    'org.homebus.experimental.ch4-sensor',
    'org.homebus.experimental.co-sensor',
    'org.homebus.experimental.co2-sensor',
    'org.homebus.experimental.covid-cases',
    'org.homebus.experimental.covid-hospitalizations',
    'org.homebus.experimental.covid-vaccinations',
    'org.homebus.experimental.diagnostic',
    'org.homebus.experimental.h2co-sensor',
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
    'org.homebus.experimental.origin',
    'org.homebus.experimental.radiation-sensor',
    'org.homebus.experimental.server-status',
    'org.homebus.experimental.soil-sensor',
    'org.homebus.experimental.solar-clock',
    'org.homebus.experimental.switch',
    'org.homebus.experimental.system',
    'org.homebus.experimental.temperature-sensor',
    'org.homebus.experimental.uninterruptible-power-supply',
    'org.homebus.experimental.uv-light-sensor',
    'org.homebus.experimental.voc-sensor',
    'org.homebus.experimental.weather',
    'org.homebus.experimental.weather-forecast'
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

#    _create_buckets
  end

  def work!
    DDCS.each do |ddc|
      @device.provision.broker.subscribe!(ddc)
    end

    listen!
  end

  def receive!(msg)
    # we don't currently store arrays
    if msg[:payload].class != Hash
      return
    end

    data = InfluxDB2::Point.new(name: msg[:ddc])
                                  .add_tag('source', msg[:source])
                                  .time(Time.at(msg[:timestamp]), InfluxDB2::WritePrecision::SECOND)

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

  def _create_buckets
    api = InfluxDB2::API::Client.new(@client)

    organization = api.create_organizations_api
                  .get_orgs
                  .orgs
                  .select { |it| it.name == @influxdb_organization }
                  .first

    image_retention_rule = InfluxDB2::API::RetentionRule.new(type: 'expire', every_seconds: 7 * 24 * 60 * 60)
    tenyear_retention_rule = InfluxDB2::API::RetentionRule.new(type: 'expire', every_seconds: 10 * 365 * 24 * 60 * 60)

    buckets = api.create_buckets_api.get_buckets(limit: 100)

    DDCS.each do |ddc|
      if buckets.buckets.select { |b| b.name == ddc }.length > 0
        next
      end

      if ddc == 'org.experimental.homebus.image'
        request = InfluxDB2::API::PostBucketRequest.new(org_id: organization.id,
                                                        name: ddc,
                                                        retention_rules: [image_retention_rule])
        bucket = api.create_buckets_api.post_buckets(request)
      else
        request = InfluxDB2::API::PostBucketRequest.new(org_id: organization.id,
                                                        name: ddc,
                                                        retention_rules: [])
        bucket = api.create_buckets_api.post_buckets(request)
      end
    end
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
