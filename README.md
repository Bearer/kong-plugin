# Bearer Kong Plugin

[Bearer](https://bearer.sh?utm_medium=docs&utm_campaign=partners&utm_source=kong) helps security teams remediate security and compliance risks by discovering, managing, and securing their API usage.

The Bearer Kong plugin allows you:

* Instantly catalog your APIs.
* Automatically map data flows to and from your APIs.

The plugin leverages an asynchronous design to minimize its impact on the latency of your API calls. It has low CPU and memory consumption.

If you need help with installation, drop us a line at support@bearer.sh or contact us [here](https://www.bearer.sh/demo?utm_medium=docs&utm_campaign=partners&utm_source=kong).

## Installation

### How it works

The Bearer Kong plugin captures API traffic from Kong API Gateway and sends it to a local Bearer agent for analysis.

### How to install

If the `luarocks` utility is installed in your system (this is likely the case if you used one of the official installation packages), you can install the 'rock' in your LuaRocks tree (a directory in which LuaRocks installs Lua modules).

To install the plugin using the LuaRocks repository run:

```shell
luarocks install kong-plugin-bearer
```

For alternative installation methods [see here](https://docs.konghq.com/gateway-oss/2.3.x/plugin-development/distribution/#installing-the-plugin).

### How to enable

Add `bearer` to the `plugins` value in `kong.conf`:

```ini
plugins = bundled,bearer
```

or to the `KONG_PLUGINS` environment variable:

```sh
$ export KONG_PLUGINS=bundled,bearer
```

## Development

### Building a Rock

```sh
$ luarocks --lua-dir <path_to_luajit> build --pack-binary-rock
```
