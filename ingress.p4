/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    
    bit<16> flow_id;
    register<bit<48>>(65535) last_timestamp_reg;
    bit<48> interarrival_value;

    action forward(egressSpec_t port) {
        standard_metadata.egress_spec = port;
    }
   
    action drop() {
       mark_to_drop(standard_metadata);
    }

    action get_interarrival_time() {
        bit<48> last_timestamp;
        bit<48> current_timestamp;

        hash(
            flow_id, 
            HashAlgorithm.crc16, 
                (bit<1>)0, 
                {
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr
                }, 
                (bit<16>) 65535);
        
        last_timestamp_reg.read(last_timestamp, (bit<32>)flow_id);
        current_timestamp = standard_metadata.ingress_global_timestamp;
        
        if(last_timestamp != 0) {
            interarrival_value = current_timestamp - last_timestamp;
        } else {
            interarrival_value = 0;
        }
        last_timestamp_reg.write((bit<32>)flow_id, current_timestamp);
    }

    table forwarding {
        key = {
            hdr.ethernet.dstAddr: exact;
        }
        actions = {
            forward;
            drop;
        }
        size = 1024;
        default_action = drop();
    }

    register<bit<32>>(1048576) bytes_transmitted;
    register<bit<32>>(1048576) sending_rate_prev_time;

    action update_sending_rate() {
        bit<32> bytes_transmitted_flow;
        bit<32> current_time;
        bit<32> prev_time;
        bit<32> time_diff;

        bytes_transmitted.read(bytes_transmitted_flow, (bit<32>)meta.flow_id);
        bytes_transmitted_flow = bytes_transmitted_flow + (bit<32>)hdr.ipv4.totalLen;
        bytes_transmitted.write((bit<32>)meta.flow_id, bytes_transmitted_flow);

        sending_rate_prev_time.read(prev_time, (bit<32>)meta.flow_id);
        current_time = (bit<32>)standard_metadata.ingress_global_timestamp;

        time_diff = current_time - prev_time;

        if (time_diff > 0) {
            meta.data_sent = bytes_transmitted_flow * 8;
            meta.sending_rate_time = time_diff;
        }

        sending_rate_prev_time.write((bit<32>)meta.flow_id, current_time);
    }


    apply {
        if(hdr.ipv4.isValid()){
            forwarding.apply();

            get_interarrival_time();
            meta.interarrival_value = interarrival_value;

            update_sending_rate();
        }
    }
}
