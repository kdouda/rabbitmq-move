# rabbitmq-move

🥄⛏️ Bash CLI utility for moving RabbitMQ messages using the Shovel interface. No admin UI needed§

## Description

Circumvents the admin UI for moving messages between queues (or different instances) in RabbitMQ. Intended to be a script used for creating terminal shortcuts (aliases) for repeated tasks (ie re-running dead letter queue messages manually).

## Getting Started

### Dependencies

* curl
* getopts
* RabbitMQ server with the shovel api plugin enabled.

### Installing

Clone this project `git clone https://github.com/kdouda/rabbitmq-move`, or simply download the rabbit_move.sh script into your preferred directory and give it execution permissions (`chmod +x rabbitmq_move.sh`).

### Executing program

For example, if we are running the API on localhost:15672 and we want to move messages from queue `queue-from` to `queue-to` on the RabbitMQ server running on localhost, we run the script with the following parameters:

```bash
./rabbit_move.sh -h http://guest:guest@localhost:15672 -f queue-from -t queue-to -s amqp://guest:guest@localhost/%2f
```

### Parameters

* `-h` Hostname of the RabbitMQ API, including the protocol (http(s)) and the port, username and password and the vhost. Required. VHost must be percent encoded.
* `-v` VHost, defaults to / (%2f), optional. Must be percent encoded. ❗ Used for the management API only.
* `-s` Source AMQP server (amqp://), including the vhost, required.
* `-d` Destination AMQP server (amqp://), optional. If not provided, defaults to the source server parameter `-s`.
* `-f` Name of the source queue (where the messages are taken from), required.
* `-t` Name of the destination queue (where the messages are sent to), required. Must not be the same as `-f`.
* `-n` Name of the shovel, optional. Defaults to `move-shell-script`.

Providing an invalid parameter (or no parameters) will result in an error message being shown.

### Alias

For example, if we want to create a shell alias for the previously provided script, we could do something akin to the following:

```bash
alias empty_queue="PATH_TO/rabbit_move.sh -h http://guest:guest@localhost:15672 -f queue-from -t queue-to -s amqp://guest:guest@localhost/%2f"
```

If you have multiple aliases using this script, it may be wise to use environment variables to replace the shared parts of the alias command.

## Version History

* 0.1
  * Initial Release

## License

This project is licensed under the MIT license. But if you for any reason use this, please do let me know, I'd love to know!

## Acknowledgments

* [leogtzr/minimal-safe-bash-template](https://github.com/leogtzr/minimal-safe-bash-template/blob/main/template-v1.sh) for the basis of the Bash script