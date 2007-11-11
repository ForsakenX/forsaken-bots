/*****************************************************************************

$Id: eventmachine.h 502 2007-08-24 09:29:53Z blackhedd $

File:     eventmachine.h
Date:     15Apr06

Copyright (C) 2006-07 by Francis Cianfrocca. All Rights Reserved.
Gmail: blackhedd

This program is free software; you can redistribute it and/or modify
it under the terms of either: 1) the GNU General Public License
as published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version; or 2) Ruby's License.

See the file COPYING for complete licensing information.

*****************************************************************************/

#ifndef __EVMA_EventMachine__H_
#define __EVMA_EventMachine__H_

#if __cplusplus
extern "C" {
#endif

	enum { // Event names
		EM_TIMER_FIRED = 100,
		EM_CONNECTION_READ = 101,
		EM_CONNECTION_UNBOUND = 102,
		EM_CONNECTION_ACCEPTED = 103,
		EM_CONNECTION_COMPLETED = 104,
		EM_LOOPBREAK_SIGNAL = 105
	};

	void evma_initialize_library (void(*)(const char*, int, const char*, int));
	void evma_run_machine();
	void evma_release_library();
	const char *evma_install_oneshot_timer (int seconds);
	const char *evma_connect_to_server (const char *server, int port);
	const char *evma_connect_to_unix_server (const char *server);
	void evma_stop_tcp_server (const char *signature);
	const char *evma_create_tcp_server (const char *address, int port);
	const char *evma_create_unix_domain_server (const char *filename);
	const char *evma_open_datagram_socket (const char *server, int port);
	const char *evma_open_keyboard();
	void evma_set_tls_parms (const char *binding, const char *privatekey_filename, const char *certchain_filenane);
	void evma_start_tls (const char *binding);
	int evma_get_peername (const char *binding, struct sockaddr*);
	int evma_get_subprocess_pid (const char *binding, pid_t*);
	int evma_send_data_to_connection (const char *binding, const char *data, int data_length);
	int evma_send_datagram (const char *binding, const char *data, int data_length, const char *address, int port);
	int evma_get_comm_inactivity_timeout (const char *binding, /*out*/int *value);
	int evma_set_comm_inactivity_timeout (const char *binding, /*in,out*/int *value);
	int evma_get_outbound_data_size (const char *binding);
	int evma_send_file_data_to_connection (const char *binding, const char *filename);

	void evma_close_connection (const char *binding, int after_writing);
	void evma_signal_loopbreak();
	void evma_set_timer_quantum (int);
	void evma_setuid_string (const char *username);
	void evma_stop_machine();

	const char *evma__write_file (const char *filename);
	const char *evma_popen (char * const*cmd_strings);

	int evma_set_rlimit_nofile (int n_files);

	// Temporary:
	void evma__epoll();

#if __cplusplus
}
#endif


#endif // __EventMachine__H_

