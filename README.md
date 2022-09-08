# homebus-influxdb

![rspec](https://github.com/github/docs/actions/workflows/rspec.yml/badge.svg)


This is a simple HomeBus component which subscribes to all the topics
available on a network and records all incoming data to InfluxDB.

## Usage

You should first login to the Homebus server using `homebus-cli`. Then
when you run `homebus-influxdb`, it will request permission to join
the network and when granted will start silently recording data to the server.

```
bundle exec homebus-influxdb
```

## Configuration

Create a `.env` file and set the variable `INFLUXDB_URL` to the URL for
the InfluxDB instance you want to use.
```
INFLUXDB_URL=http:://hostname:port
INFLUXDB_TOKEN=
INFLUXDB_ORGANIZATION=
INFLUXDB_BUCKET=homebus
```

If your InfluxDB server is not on the same local network as the client
we strongly recommend using `https` rather than `http`; otherwise your
API key and all your data will be visible to eavesdroppers.


## InfluxDB Mapping

All data will be stored as series inside the specified bucket.

Each series will have its Homebus `source` ID used as a tag and all
other attributes will be fields.

## TODO

- read list of published DDCs from `org.experimental.homebus.devices`
  and automatically request permission to receive new DDCs
- provide a way to exclude DDCs
- provide a way to exclude devices
- provide a way to expire data


# LICENSE

This software is published under the [MIT License](https://romkey.mit-license.org).
