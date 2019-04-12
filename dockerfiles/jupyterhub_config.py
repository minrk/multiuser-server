# docker image uses dummy+simple combo by default
# so it can be used for demos

c.JupyterHub.authenticator_class = 'dummy'
c.JupyterHub.spawner_class = 'simple'
