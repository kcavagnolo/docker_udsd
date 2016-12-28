import os
from IPython.lib import passwd

c.NotebookApp.ip = '*'
c.NotebookApp.port = int(os.getenv('PORT', 8888))
c.NotebookApp.open_browser = False
c.MultiKernelManager.default_kernel_name = 'python'

if 'PASSWORD' in os.environ:
      c.NotebookApp.password = passwd(os.environ['PASSWORD'])
      del os.environ['PASSWORD']
else:
    c.NotebookApp.password = u'sha1:2e8b7aab89b1:db8025c77c1764930113c8fe7de055a8466f0835'
