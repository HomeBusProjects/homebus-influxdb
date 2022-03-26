#!/usr/bin/env ruby

require './options'
require './app'

influxdb_app_options = InfluxDBHomebusAppOptions.new

influxdb = InfluxDBHomebusApp.new influxdb_app_options.options
influxdb.run!
