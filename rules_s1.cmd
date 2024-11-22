mirroring_add 5 2
table_add MyIngress.forwarding MyIngress.forward 00:00:00:00:00:01 => 0
table_add MyIngress.forwarding MyIngress.forward 00:00:00:00:00:02 => 1
table_add MyIngress.forwarding MyIngress.forward 00:00:00:00:00:03 => 2
table_add MyEgress.add_queue_statistics MyEgress.add_sw_stats 2001 => 1