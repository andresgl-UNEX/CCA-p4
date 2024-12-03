/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

#define PKT_INSTANCE_TYPE_INGRESS_CLONE 1

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {

    
    action add_sw_stats(switch_ID_t ID){
        hdr.report.setValid();
        hdr.report.ingress_timestamp = standard_metadata.ingress_global_timestamp;
        hdr.report.egress_timestamp = standard_metadata.egress_global_timestamp;
        hdr.report.q_delay = standard_metadata.egress_global_timestamp
                                    - standard_metadata.ingress_global_timestamp;
        hdr.report.q_depth = (bit<24>)standard_metadata.enq_qdepth;
        hdr.report.switch_ID = ID;

        hdr.report.interarrival_value = meta.interarrival_value;

        hdr.report.sending_rate_time = meta.sending_rate_time;
        hdr.report.sending_rate_current_time = meta.sending_rate_current_time;
        hdr.report.sending_rate_prev_time = meta.sending_rate_prev_time;
        // hdr.report.loss_rate = meta.loss_rate;
        hdr.report.packets_sent = meta.packets_sent;
        hdr.report.data_sent = meta.data_sent;
        hdr.report.packets_received = meta.packets_received;
        hdr.report.data_received = meta.data_received;
        hdr.report.interarrival_value = meta.interarrival_value;

        hdr.ipv4.totalLen = hdr.ipv4.totalLen + 22;
    }
   
    action drop() {
       mark_to_drop(standard_metadata);
    }

    register<bit<32>>(1048576) bytes_received;

    action update_loss_rate() {
        bit<32> bytes_received_flow;

        bytes_received.read(bytes_received_flow, (bit<32>)meta.flow_id);
        bytes_received_flow = bytes_received_flow + (bit<32>)hdr.ipv4.totalLen;
        bytes_received.write((bit<32>)meta.flow_id, bytes_received_flow);

        meta.data_received = bytes_received_flow * 8;
    }

    table add_queue_statistics {
        key = {
            hdr.tcp.dstPort: exact;
        }
        actions = {
            add_sw_stats;
            NoAction;
        }
        size = 32;
        default_action = NoAction;
    }


    apply {
        if(hdr.ipv4.isValid()){
            add_queue_statistics.apply();
        }
        else {
            update_loss_rate();
        }
    }     
}
