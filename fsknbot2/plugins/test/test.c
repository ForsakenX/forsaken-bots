#include <stdio.h>
#include <string.h>
#include <enet/enet.h>

int main (int argc, char ** argv) 
{
    ENetAddress address;
    ENetHost * client;
    ENetEvent event;
    ENetPeer *peer;

    if (argc < 3)
    {
	fprintf(stderr,"Usage: ./client address port\n");
	exit(1);
    }

    if (enet_initialize () != 0)
    {
        fprintf (stderr, "An error occurred while initializing ENet.\n");
        exit(1);
    }

    client = enet_host_create( NULL, 32, 0, 0 );

    if (client == NULL)
    {
        fprintf (stderr, "error while trying to create an ENet client.\n");
        exit (1);
    }

    fprintf(stderr,"Address %s Port %d\n",(char*)argv[1],atoi(argv[2]));

    enet_address_set_host (&address, (char*)argv[1]); 
    address.port = atoi(argv[2]);

    peer = enet_host_connect( client, &address, 3 );

    if (peer == NULL)
    {
      fprintf(stderr,"No peers for initiating an ENet connection.\n");
      exit (1);
    }

    fprintf(stderr,"Connecting...\n");

    if ( enet_host_service( client, &event, 1000 ) <= 0 || event.type != ENET_EVENT_TYPE_CONNECT )
    {
        enet_peer_reset (peer);
        puts("Connection failed...");
        exit (1);
    }

    puts("Connection succeeded!");

    enet_host_destroy(client);
    atexit (enet_deinitialize);

    exit(0); // success
}
