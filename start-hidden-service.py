#GPL-3 - See LICENSE file for copyright and license details.
import os
import sys
from stem.control import Controller

print('  ## Connecting to tor')

with Controller.from_port() as controller:
  controller.authenticate()

  hidden_service_dir = os.path.join(controller.get_conf('DataDirectory'), sys.argv[1])

  # Create a hidden service where visitors of port 80 get redirected to local port argv[2]
  print("  ## creating hidden service in %s" % hidden_service_dir)
  result = controller.create_hidden_service(hidden_service_dir, sys.argv[3], target_port = sys.argv[2])

  # The hostname is only available when we can read the hidden service
  # directory. This requires us to be running with the same user as tor.
  if result:
    if result.hostname:
      print("  ## Our service is available at %s" % result.hostname)
