#!/usr/bin/env bash
#: Simple RabbitMQ shovel CLI utility using the HTTP api to save me (and possibly you) the need to install the CLI on your local machine and the need to access the web UI.
#: You can set up Shell aliases to handle periodically occuring tasks using one command from the CLI.

set -o errexit
set -o nounset
set -o pipefail

work_dir=$(dirname "$(readlink --canonicalize-existing "${0}" 2> /dev/null)")
readonly script_name="${0##*/}"

rabbitmq_hostname=""
rabbitmq_queue_source=""
rabbitmq_queue_destination=""
rabbitmq_vhost="%2f"

rabbitmq_source_hostname=""
rabbitmq_destination_hostname=""

shovel_name="move-shell-script"

trap clean_up ERR EXIT SIGINT SIGTERM

usage() {
    cat <<USAGE_TEXT
Usage: ${script_name} [-h | --help] [-a <ARG>] [--abc <ARG>] [-f | --flag]

DESCRIPTION
    RabbitMQ HTTP API utility to shovel messages from queue A to queue B.

    OPTIONS:

    -h
        Hostname of RabbitMQ API, including the protocol (http(s), amqp(s)) and the port, username and password and the vhost. VHost must be percent encoded.

    -s
        Source AMQP server (amqp://).

    -d
        Destination AMQP server (amqp://).

    -f
        Name of the source queue (where the messages are taken from).

    -t
        Name of the destination queue (where the messages are sent to).

    -v 
        VHost, defaults to / (%2f). Must be percent encoded.

    -n
        Name of the shovel, optional.

USAGE_TEXT
}

clean_up() {
    trap - ERR EXIT SIGINT SIGTERM
}

die() {
    local -r msg="${1}"
    local -r code="${2:-90}"
    echo "${msg}" >&2
    exit "${code}"
}

parse_user_options() {
    while getopts "h:f:t:s:d:v:" opt; do
        case "${opt}" in
            h)
                rabbitmq_hostname="${OPTARG}"
                ;;
            f)
                rabbitmq_queue_source="${OPTARG}"
                ;;
            t)
                rabbitmq_queue_destination="${OPTARG}"
                ;;
            s)
                rabbitmq_source_hostname="${OPTARG}"
                ;;
            d)
                rabbitmq_destination_hostname="${OPTARG}"
                ;;
            v)
                rabbitmq_vhost="${OPTARG}"
                ;;
            *)
                usage
                die "error: parsing options" 1
                ;;
        esac
    done
}

parse_user_options "${@}"

invalid_flag=0

if [ -z "${rabbitmq_hostname}" ]; then
    invalid_flag=1
    echo "Missing hostname, specify it with -h parameter"
fi

if [ -z "${rabbitmq_queue_source}" ]; then
    invalid_flag=1
    echo "Missing queue from, specify it with -f parameter"
fi

if [ -z "${rabbitmq_queue_destination}" ]; then
    invalid_flag=1
    echo "Missing queue to, specify it with -t parameter"
fi

if [ -z "${rabbitmq_source_hostname}" ]; then
    invalid_flag=1
    echo "Missing AMQP source hostname, specify it with -s parameter"
fi

if [ -z "${rabbitmq_destination_hostname}" ]; then
    rabbitmq_destination_hostname="${rabbitmq_source_hostname}"
fi

if ((invalid_flag)); then
    die "Cannot proceed with missing required parameters." 1
fi

if [ "$rabbitmq_queue_source" = "$rabbitmq_queue_destination" ]; then
    die "Cannot shovel from messages from the same queue (${rabbitmq_queue_source} -> ${rabbitmq_queue_destination})." 1
fi

curl -v -X PUT $rabbitmq_hostname/api/parameters/shovel/$rabbitmq_vhost/$shovel_name \
        -H "content-type: application/json" \
        -d @- <<EOF
{
  "value": {
    "src-protocol": "amqp091",
    "src-uri": "$rabbitmq_source_hostname",
    "src-queue": "$rabbitmq_queue_source",
    "dest-protocol": "amqp091",
    "dest-uri": "$rabbitmq_destination_hostname",
    "dest-queue": "$rabbitmq_queue_destination",
    "src-delete-after": "queue-length"
  }
}
EOF

#,"src-delete-after": "queue-length"

echo "Shovel created."

exit 0