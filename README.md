# CCA-p4

To execute, compile the basic.p4 file and push the basic.json (created from the compilation) and rules_s1.cmd files.

Once the files are in the p4 switch *s1*, execute the following commands:
```
simple_switch -i 0@s1-eth0 -i 1@s1-eth2 -i 2@s1-eth1 basic.json &
```
```
simple_switch_CLI < rules_s1.cmd
```
In the topology, the hosts play the following roles and the corresponding commands have to be executed:

- **h1:** is the client, run ```iperf3 -c 10.0.0.2 -O 5```.
- **h2:** is the server, execute ```iperf3 -s```.
- **h3:** is the host where all packets are duplicated and the one used to display the metrics, run ```get_rtts.py```.
