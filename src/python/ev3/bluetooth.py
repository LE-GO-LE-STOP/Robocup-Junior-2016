import bluetooth as bt
import select

# Arbitrary constants used for port discovery
EV3BluetoothServiceName = "EV3-BT"
EV3BluetoothServiceUUID = "969a425d-a15c-4e07-934a-f3bc659ed170"

class BluetoothDiscoveryException(Exception):
	def __init__(self, message):
		self.msg = message

class BluetoothSocket:
	def __init__(protocol):
		if protocol == "RFCOMM":
			self._socket = bt.BluetoothSocket(bt.RFCOMM)
			self._protocol = bt.RFCOMM
		elif protocol == "L2CAP":
			self._socket = bt.BluetoothSocket(bt.L2CAP)
			self._protocol = bt.L2CAP

		self._socket.setblocking(0)

	def send(self, data):
		self._socket.sendall(data)

	def receive(self, bufferSize=1024):
		ready = select.select([self._socket], [], [], 0)
		if ready[0]:
			return self._socket.recv(bufferSize)

	def close(self):
		self._socket.close()


class BluetoothClient(BluetoothSocket):
	def __init__(self, address, port, protocol="RFCOMM"):
		super().__init__(protocol)

		if port == None:
			services = bt.find_service(EV3BluetoothServiceName, EV3BluetoothServiceUUID, address)

			if len(services) == 0:
				raise BluetoothDiscoveryException("No service is advertising a compatible port")

			for service in services:
				if service["protocol"] == protocol:
					address = service["host"] # Connect to the newly discovered server instead of the SDP server
					port = service["port"]
					break

		self._clientSocket.connect((address, port))

class BluetoothServer(BluetoothSocket):
	def __init__(self, port, protocol="RFCOMM", advertise=False):
		super().__init__(protocol)

		if port == None:
			port = bt.get_available_port(self._protocol)

		self._socket.bind(("", port))
		self._socket.listen(1)

		self._clients = []

		if advertise:
			bt.advertise_service(self._socket, EV3BluetoothServiceName, EV3BluetoothServiceUUID)

	def acceptClient(self):
		clientSocket, address = self._serverSocket.accept()

		if clientSocket == None

		client = BluetoothServer_Client(clientSocket)
		self._clients.append(client)
		return client

	def send(self, data):
		for client in self._clients:
			client.send(data)

	def close(self):
		for client in self._clients:
			client.close()

		super().close()


class BluetoothServer_Client(BluetoothSocket):
	def __init__(self, socket):
		self._socket = socket

	def receive(self):
		pass
	

class Bluetooth:
	@staticmethod
	def scan(self):
		visibleDevices = []
		devices = bt.discover_devices();

		for address in devices:
			deviceName = bt.lookup_name(address)
			visibleDevices.append((deviceName,address))

		return visibleDevices

	@staticmethod
	def startServer(self, port, protocol, advertise):
		return BluetoothServer(port, protocol, advertise)

	@staticmethod
	def connect(self, address, port):
		return BluetoothClient(address, port)