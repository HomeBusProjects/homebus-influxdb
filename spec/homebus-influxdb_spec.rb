require 'spec_helper'

require 'homebus-influxdb/version'
require 'homebus-influxdb/options'
require 'homebus-influxdb/app'

describe HomebusInfluxdb do
  context "Version number" do
    it "Has a version number" do
      expect(HomebusInfluxdb::VERSION).not_to be_nil
      expect(HomebusInfluxdb::VERSION.class).to be String
    end
  end 
end

describe HomebusInfluxdb::Options do
  context "Methods" do
    options = HomebusInfluxdb::Options.new

    it "Has a version number" do
      expect(options.version).not_to be_nil
      expect(options.version.class).to be String
    end

    it "Uses the VERSION constant" do
      expect(options.version).to eq(HomebusInfluxdb::VERSION)
    end

    it "Has a name" do
      expect(options.name).not_to be_nil
      expect(options.name.class).to be String
    end

    it "Has a banner" do
      expect(options.banner).not_to be_nil
      expect(options.banner.class).to be String
    end
  end
end

describe HomebusInfluxdb::App do
  context "Methods" do
    options = HomebusInfluxdb::Options.new
    app = HomebusInfluxdb::App.new(options)

    it "Has a name" do
      expect(app.name).not_to be_nil
      expect(app.name.class).to be String
    end

    it "Consumes" do
      expect(app.consumes).not_to be_nil
      expect(app.consumes.class).to be Array
    end

    it "Publishes" do
      expect(app.publishes).not_to be_nil
      expect(app.publishes.class).to be Array
    end

    it "Has devices" do
      expect(app.devices).not_to be_nil
      expect(app.devices.class).to be Array
    end
  end
end