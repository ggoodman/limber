# Main Application Config
# -----------------------
# Optional config files can be added to /config/environments/<SS_ENV>.coffee (e.g. /config/environments/development.coffee)
# giving you the opportunity to override each setting on a per-environment basis
# Tip: Type 'SS.config' into the SocketStream Console to see the full list of possible config options and view the current settings

exports.config =

  # HTTP server (becomes secondary server when HTTPS is enabled)
  http:
    port:         process.env.C9_PORT
    hostname:     "0.0.0.0"
  
  # HTTPS server (becomes primary server if enabled)
  https:
    enabled:      false
    port:         443
    domain:       "www.socketstream.org"

  # HTTP(S) request-based API
  api:
    enabled:      true
    prefix:       'api'
    https_only:   false

  # Show customizable 'Incompatible Browser' page if browser does not support websockets
  browser_check:
    enabled:      false
    strict:       true

  # Load balancing. Uncomment and set suitable TCP values for your network once you're ready to run across multiple boxes
  #cluster:
  #  sockets:
  #    fe_main:    "tcp://10.0.0.10:9000"
  #    fe_pub:     "tcp://10.0.0.10:9001"
  #    be_main:    "tcp://10.1.1.10:9000"
  
  redis:
    host: "icefish.redistogo.com"
    port: 9410
    password: "6f4d7cf6402c6fe4f6ab8599881c6a3d"