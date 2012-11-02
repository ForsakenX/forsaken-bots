#include <stdio.h>
#include <string.h>
#include <enet.h>

int main (int argc, char ** argv) 
{
    ENetAddress address;
    ENetHost * host;
    ENetEvent event;
    ENetPeer *peer;

    if (argc < 2)
    {
			fprintf(stderr,"Usage: ./host port\n");
			exit(1);
    }

    if (enet_initialize () != 0)
    {
        fprintf (stderr, "An error occurred while initializing ENet.\n");
        exit(1);
    }

		address.host = ENET_HOST_ANY;
		address.port = atoi(argv[1]);

    host = enet_host_create( &address, 32, 2, 0 );

    if (host == NULL)
    {
        fprintf (stderr, "error while trying to create an ENet host.\n");
        exit (1);
    }

    fprintf(stderr,"Running");

    while ( enet_host_service( host, &event, 1000 ) > 0 )
    {
			fprintf(stderr,".");
    }

    enet_host_destroy(host);
    atexit (enet_deinitialize);

    exit(0); // success
}
