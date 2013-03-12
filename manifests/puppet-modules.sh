#!/bin/sh
# This script will get all puppet modules required
# for the deployment of the Cisco OpenStack Edition (COE).
# Set REPO_NAME below to the name of the apt repository you want to use.
# Choices include:
#    * A main release repo.  This will include the latest tested and 
#      released modules.  This is the recommended choice for most users.
#      Example: "folsom"
#    * A proposed repo.  This includes the latest code that developers have
#      committed.  It is considered bleeding edge and may not have been
#      fully vetted.  This is recommended only for developers.
#      Example: "folsom-proposed"
#    * A specific maintenance release repo.  This allows you to download
#      modules from a specific release.  This is recomended option if you
#      have qualified only a specific release for your environment and do
#      not wish to (yet) use the latest stable updates.
#      Example: "folsom/snapshots/2012.2.2"
#
# If you require a proxy to reach the internet, set appropriate values
# for HTTP_PROXY, HTTPS_PROXY, FTP_PROXY, and/or NO_PROXY below.  If you
# don't specify a value for any of those variables, none will be used.
echo "Getting Puppet Modules"
REPO_NAME=folsom-proposed
FILE_LIST=modules.list
#REPO=http://128.107.252.163/openstack/cisco
REPO=ftp://ftpeng.cisco.com/openstack/cisco
PUPPET_PATH=/etc/puppet/
APT_CONFIG_FILE=/etc/apt/sources.list.d/cisco-openstack-mirror_folsom.list
HTTP_PROXY=
HTTPS_PROXY=
NO_PROXY=
FTP_PROXY=

# Export proxy statements into the environment.
if [ HTTP_PROXY ]
	then
	export HTTP_PROXY=$HTTP_PROXY
fi
if [ HTTPS_PROXY ]
        then
        export HTTPS_PROXY=$HTTPS_PROXY
fi
if [ FTP_PROXY ]
        then
        export FTP_PROXY=$FTP_PROXY
fi
if [ NO_PROXY ]
        then
        export NO_PROXY=$NO_PROXY
fi



# Install the repo key.
echo '-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.11 (GNU/Linux)

mQENBE/oXVkBCACcjAcV7lRGskECEHovgZ6a2robpBroQBW+tJds7B+qn/DslOAN
1hm0UuGQsi8pNzHDE29FMO3yOhmkenDd1V/T6tHNXqhHvf55nL6anlzwMmq3syIS
uqVjeMMXbZ4d+Rh0K/rI4TyRbUiI2DDLP+6wYeh1pTPwrleHm5FXBMDbU/OZ5vKZ
67j99GaARYxHp8W/be8KRSoV9wU1WXr4+GA6K7ENe2A8PT+jH79Sr4kF4uKC3VxD
BF5Z0yaLqr+1V2pHU3AfmybOCmoPYviOqpwj3FQ2PhtObLs+hq7zCviDTX2IxHBb
Q3mGsD8wS9uyZcHN77maAzZlL5G794DEr1NLABEBAAG0NU9wZW5TdGFja0BDaXNj
byBBUFQgcmVwbyA8b3BlbnN0YWNrLWJ1aWxkZEBjaXNjby5jb20+iQE4BBMBAgAi
BQJP6F1ZAhsDBgsJCAcDAgYVCAIJCgsEFgIDAQIeAQIXgAAKCRDozGcFPtOxmXcK
B/9WvQrBwxmIMV2M+VMBhQqtipvJeDX2Uv34Ytpsg2jldl0TS8XheGlUNZ5djxDy
u3X0hKwRLeOppV09GVO3wGizNCV1EJjqQbCMkq6VSJjD1B/6Tg+3M/XmNaKHK3Op
zSi+35OQ6xXc38DUOrigaCZUU40nGQeYUMRYzI+d3pPlNd0+nLndrE4rNNFB91dM
BTeoyQMWd6tpTwz5MAi+I11tCIQAPCSG1qR52R3bog/0PlJzilxjkdShl1Cj0RmX
7bHIMD66uC1FKCpbRaiPR8XmTPLv29ZTk1ABBzoynZyFDfliRwQi6TS20TuEj+ZH
xq/T6MM6+rpdBVz62ek6/KBcuQENBE/oXVkBCACgzyyGvvHLx7g/Rpys1WdevYMH
THBS24RMaDHqg7H7xe0fFzmiblWjV8V4Yy+heLLV5nTYBQLS43MFvFbnFvB3ygDI
IdVjLVDXcPfcp+Np2PE8cJuDEE4seGU26UoJ2pPK/IHbnmGWYwXJBbik9YepD61c
NJ5XMzMYI5z9/YNupeJoy8/8uxdxI/B66PL9QN8wKBk5js2OX8TtEjmEZSrZrIuM
rVVXRU/1m732lhIyVVws4StRkpG+D15Dp98yDGjbCRREzZPeKHpvO/Uhn23hVyHe
PIc+bu1mXMQ+N/3UjXtfUg27hmmgBDAjxUeSb1moFpeqLys2AAY+yXiHDv57ABEB
AAGJAR8EGAECAAkFAk/oXVkCGwwACgkQ6MxnBT7TsZng+AgAnFogD90f3ByTVlNp
Sb+HHd/cPqZ83RB9XUxRRnkIQmOozUjw8nq8I8eTT4t0Sa8G9q1fl14tXIJ9szzz
BUIYyda/RYZszL9rHhucSfFIkpnp7ddfE9NDlnZUvavnnyRsWpIZa6hJq8hQEp92
IQBF6R7wOws0A0oUmME25Rzam9qVbywOh9ZQvzYPpFaEmmjpCRDxJLB1DYu8lnC4
h1jP1GXFUIQDbcznrR2MQDy5fNt678HcIqMwVp2CJz/2jrZlbSKfMckdpbiWNns/
xKyLYs5m34d4a0it6wsMem3YCefSYBjyLGSd/kCI/CgOdGN1ZY1HSdLmmjiDkQPQ
UcXHbA==
=v6jg
-----END PGP PUBLIC KEY BLOCK-----' | apt-key add -

# Make sure we have the repository.
if [ ! -f $APT_CONFIG_FILE ]
	then
	echo "# cisco-openstack-mirror_folsom" > $APT_CONFIG_FILE
	echo "deb $REPO $REPO_NAME  main" >> $APT_CONFIG_FILE
	echo "deb-src $REPO $REPO_NAME main" >> $APT_CONFIG_FILE
else
        echo "Repo already configured in $APT_CONFIG_FILE; assuming it is correct and not adding an additional repo configuration."
fi

# Update the apt cache.
apt-get update

# Now start installing modules.
awk '{ printf "puppet-%s ", $0 }' modules.list  | xargs apt-get install
