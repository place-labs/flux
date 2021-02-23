# flux

Client library for pushing data to, and querying information from InfluxDB v2.x.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  flux:
    github: place-labs/flux
```

2. Run `shards install`

## Usage

```crystal
require "flux"
```

### Configure the client

Define your client configuration with `Flux.configure`. This yields an
[`Options`](https://github.com/place-labs/flux/blob/master/src/flux.cr#L7-L15) object
with appriopriate setters.

```crystal
Flux.configure do |settings|
  settings.uri     = ENV["INFLUX_URI"]? || abort "INFLUX_URI env var not set"
  settings.api_key = ENV["INFLUX_API_KEY"]? || abort "INFLUX_API_KEY env var not set"
  settings.org     = ENV["INFLUX_ORG"]? || "vandelay-industries"
  settings.bucket  = ENV["INFLUX_BUCKET"]? || "latex-sales"
end
```

### Writing data

Use `Flux.write` to enqueue a point. Writes are automatically buffered and
flushed after either a time delay or optimal write size.

### Running queries

Once information is available in the bucket, queries are executed with
`Flux.query`.  This accepts a [Flux
expression](https://v2.docs.influxdata.com/v2.0/reference/flux/).

### Parallel clients

If your application requires connectivity with more that one InfluxDB instance
or bucket, clients can be directly created with `Flux::Client.new`.

## Contributing

1. Fork it (<https://github.com/place-labs/flux/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Kim Burgess](https://github.com/kimburgess) - creator and maintainer
