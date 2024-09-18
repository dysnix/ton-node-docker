import sys
import socket
import struct

ip = sys.argv[1]
print(struct.unpack('>i', socket.inet_aton(ip))[0])
