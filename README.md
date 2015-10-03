# ssh-tunnel-link

ssh-tunnel-link is a docker image for linking docker containers
between different hosts through ssh-tunnels. This allows you to
connect to already running containers on a remote host without having
to expose ports locally or publicly. You could even use it to connect
to local running containers without exposing their ports locally.

Note that this images is not intended for creating permanent links
between production servers, though possible, there are better
alternatives for permanent encrypted links between production
containers.

The intended goal of this image is to allow access to web based admin
control panels, control terminals, and similar, temporarily (or even
permanently) from a remote machine without having to expose such ports
locally or publicly and avoid the need for access control and
firewalls.

A good example of intended usage is accessing the admin GUI of a
Solr image running on a remote host without having to expose its
port or setting up access control.

The image is used both server side and client side by running in
different modes.

## Setting up a public/private key-pair

Before using the image you need to set up a pair of ssh-keys. You can
store the keys in a folder (which we will do in this example), or if
you prefer, create your own data container containing the keys.

Create a folder on the server to contain the keys:

`mkdir -p /some/folder/keys && cd /some/folder/keys`

Create a public/private key-pair:

`ssh-keygen -t rsa -b 4096 -f "id_rsa" -N '' -C ''`

Copy the keys to the client machine(s). For good measure you should
probably delete the private key from the server for good security
measure.

## Setting up the server

For this example we assume you have a docker container running on your
server running Solr that you want to access the control panel GUI of
on a remote machine. The running docker container is named solr in
this example.

Run the following command:

`docker run -d --name ssh-tunnel-server -v /some/folder/keys:/keys -p
2222:2222 --link solr:solr deadcyclo/ssh-tunnel-link:latest server`

If you want to you can link to multiple containers, as many as you
like, allowing linking to any listening ports in any of the containers
from your client machine.

## Setting up the client

Now, on the client we want to start the docker container in client
mode, creating a tunnel to your solr container and exposing the solr
port on your local machine. Run the following command:

`docker run -d --name ssh-tunnel-client -v /some/folder/keys:/keys -p
8983:8983 -e SSH_TUNNEL_SOLR_8983=8983:solr:serverhostname
deadcyclo/ssh-tunnel-link:latest client`

Now you can access your solr control panel through
`http://localhost:8983/solr/` on your client.

Lets explain what each individual parameter here is:

`docker run -d --name ssh-tunnel-client -v /some/folder/keys:/keys -p
8983:8983 -e
SSH_TUNNEL_<TUNNEL_NAME>_<LOCAL_PORT>=<REMOTE_PORT>:<LOCAL_HOST>:<REMOTE_HOST>
deadcyclo/ssh-tunnel-link:latest client`

The variable TUNNEL_NAME is the name of your tunnel. The name itself
isn't important, but it must be unique within the given container and
consist of uppercase A-Z. REMOTE_PORT is the port listening in the
container your are linking to on the server that you want to
access. LOCAL_HOST is the internal host name in the docker container
you are linking to on the server that you want to access. REMOTE_HOST
is the host name of your server.

You can specify multiple environment variables in this format on a
single container to link to multiple ports running in (a) container(s)
on the server.

Naturally, you could also start the client container without exposing
the ports, and rather link to it from one or more local containers, or
even combine exposing ports and linking containers.

## Other available environment variables

This is a list of other optional environment variables you can specify
when running the container.

### Server mode

The ssh-server needs its own key-pair. By default this is
/keys/host.pem (so inside the folder you add your client key-pair
to). If you want to specify your own, simply create this file before
starting the container in server mode. If you want to use a completely
different key, specify the $SSH_HOST_KEY_FILE environment variable
when starting the container in server mode.

To start the ssh daemon in debug mode specify the $SSH_DEBUG_LEVEL
environment variable when starting the container in server mode. Legal
values are 1, 2 or 3.

You can also specify a different location for the public key file
authorized to access the server rather than the default
/keys/id_rsa.pub file from the mapped folder or container. Just
specify the $SSH_AUTHORIZED_KEY_FILE environment variable when
starting the container in server mode.

### Client mode

If you want to specify your own private key rather than the default
/key/id_rsa from the mapped folder or container just specify the
$SSH_IDENTITY_FILE environment variable when starting the container in
client mode.

To start the ssh client in debug mode specify the $SSH_DEBUG_LEVEL
environment variable when starting the container in client mode. Legal
values are 1, 2 or 3.

You can specify a different ssh keep-alive interval by specifying the
$SSH_SERVER_KEEPALIVE_INTERVAL environment variable when starting the
container in client mode.

Finally, if you have exposed your ssh-server on a different port than
2222 on your server, you need to specify the $SSH_PORT environment
variable indicating that change when starting your client container.

## Other ways of running the container

You might also want to do other stuff with the container, investigate
it's internals, or debug some problem you are experiencing. You can
run any legal command you want by specifying the command rather than
server or client. A good starting place would be `/bin/bash`.

