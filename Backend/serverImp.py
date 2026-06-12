"""Telemetor test backend entry point.

Replays a telemetry CSV over the frozen TCP+ACK protocol (ACK.md) to any
number of concurrent clients, each receiving the full stream.

    python Backend/serverImp.py [--host H] [--port P] [--csv FILE]
                                [--rate HZ] [--header-rows N] [--loop] [-v]
"""
import argparse
import logging
import os
import signal
import sys
import threading

from broadcaster import Broadcaster
from csv_source import CsvReplaySource
from socket_server import TelemetryServer

BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_HOST = '127.0.0.1'
DEFAULT_PORT = 12345
DEFAULT_CSV = os.path.join(BACKEND_DIR, 'rocket.csv')
DEFAULT_RATE_HZ = 50.0
DEFAULT_HEADER_ROWS = 2

logger = logging.getLogger('serverImp')


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--host', default=DEFAULT_HOST,
                        help=f'bind address (default {DEFAULT_HOST})')
    parser.add_argument('--port', type=int, default=DEFAULT_PORT,
                        help=f'TCP port (default {DEFAULT_PORT})')
    parser.add_argument('--csv', default=DEFAULT_CSV,
                        help='CSV file to replay (default rocket.csv)')
    parser.add_argument('--rate', type=float, default=DEFAULT_RATE_HZ,
                        help=f'rows per second (default {DEFAULT_RATE_HZ})')
    parser.add_argument('--header-rows', type=int,
                        default=DEFAULT_HEADER_ROWS,
                        help=f'header rows in the CSV (default '
                             f'{DEFAULT_HEADER_ROWS})')
    parser.add_argument('--loop', action='store_true',
                        help='restart the replay when the file ends')
    parser.add_argument('-v', '--verbose', action='store_true',
                        help='enable DEBUG logging (per-frame chatter)')
    return parser


def main(argv=None) -> int:
    args = build_arg_parser().parse_args(argv)
    logging.basicConfig(
        stream=sys.stdout,
        level=logging.DEBUG if args.verbose else logging.INFO,
        format='%(asctime)s %(levelname)s %(name)s - %(message)s',
        datefmt='%H:%M:%S')

    shutdown = threading.Event()

    def handle_signal(signum, frame):
        logger.info("received %s, shutting down", signal.Signals(signum).name)
        shutdown.set()

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    source = CsvReplaySource(args.csv, header_rows=args.header_rows,
                             rate_hz=args.rate, loop=args.loop)
    broadcaster = Broadcaster()
    server = TelemetryServer(args.host, args.port, broadcaster,
                             headers=source.headers, types=source.types,
                             shutdown=shutdown)
    server.start()
    source.start(broadcaster, shutdown)

    try:
        while not shutdown.is_set():
            shutdown.wait(0.5)
    finally:
        server.stop()
        source.join(timeout=5)
        logger.info("bye")
    return 0


if __name__ == '__main__':
    sys.exit(main())
