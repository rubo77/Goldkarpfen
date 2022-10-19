#GPL-3 - See LICENSE file for copyright and license details.
import os
import sys
from stem.control import Controller

print('  ## Connecting to tor')

with Controller.from_port() as controller:
  controller.authenticate()

  hidden_service_dir = os.path.join(controller.get_conf('DataDirectory'), sys.argv[1])

  print("  ## shutting down hidden service")
  controller.remove_hidden_service(hidden_service_dir)
