from mininet.net import Containernet
from mininet.node import Controller, Docker
from mininet.link import TCLink
from mininet.cli import CLI
from mininet.log import setLogLevel

def customTopology():
    # Crear la red usando Containernet
    net = Containernet(controller=Controller)

    # Añadir un controlador remoto
    net.addController('c0')

    # Creación de hosts
    h1 = net.addHost('h1', ip='10.0.0.1')
    h2 = net.addHost('h2', ip='10.0.0.2')
    h3 = net.addHost('h3', ip='10.0.0.3')

    # Creación del contenedor Docker para el switch P4 (s1)
    s1 = net.addDocker(
                        's1', 
                        ip=None, 
                        dimage='bmv2', 
                        dcmd='/bin/bash')

    # Creación de un switch estándar (s2)
    s2 = net.addSwitch('s2')

    # Creación de enlaces con configuraciones de ancho de banda
    net.addLink(h1, s1, bw=100)
    net.addLink(s1, h3, bw=100)
    net.addLink(s1, s2, bw=10)
    net.addLink(s2, h2, bw=100)

    # Iniciar la red
    net.start()

    # Configuración adicional para el contenedor Docker (s1)
    s1.cmd('/bin/bash &')  # Ejecuta un comando inicial en el contenedor

    # Abrir la CLI
    CLI(net)

    # Detener la red
    net.stop()

if __name__ == '__main__':
    setLogLevel('info')  # Nivel de logging para depuración
    customTopology()