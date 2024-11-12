/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

#define PKT_INSTANCE_TYPE_INGRESS_CLONE 1

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {

   
    action drop() {
       mark_to_drop(standard_metadata);
    }

    action compute_flow_id() {
        hash(
            meta.flow_id, 
            HashAlgorithm.crc16, 
            (bit<1>)0, 
            {
            hdr.ipv4.srcAddr,
            hdr.ipv4.dstAddr,
            hdr.ipv4.protocol,
            hdr.tcp.srcPort,
            hdr.tcp.dstPort
            }, 
            (bit<16>) 65535
        );
    }

    action mark_SEQ() {
        meta.pkt_type = PKT_TYPE_SEQ;
    }

    action mark_ACK() {
        meta.pkt_type = PKT_TYPE_ACK;
    }

    action compute_expected_ack() {
        meta.expected_ack = hdr.tcp.seqNo + ((bit<32>)(hdr.ipv4.totalLen - 
            (((bit<16>)hdr.ipv4.ihl + ((bit<16>)hdr.tcp.dataOffset)) * 16w4)));
        if(hdr.tcp.flags == TCP_FLAGS_S) {
            meta.expected_ack = meta.expected_ack + 1;
        }
    }

    action get_pkt_signature_SEQ() {
        hash (
            meta.pkt_signature,
            HashAlgorithm.crc32,
            (bit<1>)0,
            {
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr,
                hdr.tcp.srcPort,
                hdr.tcp.dstPort,
                meta.expected_ack
            },
            (bit<32>)1048576
        );
    }

    action get_pkt_signature_ACK() {
        hash (
            meta.pkt_signature,
            HashAlgorithm.crc32,
            (bit<1>)0,
            {
                hdr.ipv4.dstAddr,
                hdr.ipv4.srcAddr,
                hdr.tcp.dstPort,
                hdr.tcp.srcPort,
                hdr.tcp.ackNo
            },
            (bit<32>)1048576
        );
    }

    table get_packet_type {
        key = {
            hdr.tcp.flags: ternary;
            hdr.ipv4.totalLen: range;
        }
        actions = {
            mark_SEQ;
            mark_ACK;
            drop;
        }
        default_action = mark_SEQ();
        const entries = {
            (TCP_FLAGS_S, _) : mark_SEQ();
            (TCP_FLAGS_S + TCP_FLAGS_A, _) : mark_ACK();
            (TCP_FLAGS_A, 0..80) : mark_ACK();
            (TCP_FLAGS_A + TCP_FLAGS_P, 0..80) : mark_ACK();
            (_, 100..1600) : mark_SEQ();
            (TCP_FLAGS_R, _) : drop();
            (TCP_FLAGS_F, _) : drop();
        }
    }

    register<bit<32>>(1048576) last_timestamp_reg_rtt_e;


    apply {
        if(hdr.ipv4.isValid()){
            if(hdr.tcp.isValid()) {
                compute_flow_id();
                get_packet_type.apply();

                if(meta.pkt_type == PKT_TYPE_SEQ) {
                    compute_expected_ack();
                    get_pkt_signature_SEQ();
                    last_timestamp_reg_rtt_e.write((bit<32>)meta.pkt_signature,
                    (bit<32>)standard_metadata.ingress_global_timestamp);
                } else {
                    get_pkt_signature_ACK();
                    bit<32> extracted_ts;
                    last_timestamp_reg_rtt_e.read(extracted_ts, (bit<32>)meta.pkt_signature);
                    meta.rtt_sample_e = (bit<32>)standard_metadata.egress_global_timestamp - extracted_ts;
                    meta.return_timestamp_e = (bit<32>)standard_metadata.egress_global_timestamp;
                    meta.departure_timestamp_e = extracted_ts;
                }
            }
        }

        if(standard_metadata.instance_type == PKT_INSTANCE_TYPE_INGRESS_CLONE) {
            hdr.ethernet.etherType = 0x1234;

            hdr.report.setValid();
            hdr.report.switch_ID = meta.switch_ID;
            hdr.report.rtt = meta.rtt_sample;
            hdr.report.rtt_e = meta.rtt_sample_e;
            hdr.report.ingress_timestamp = meta.ingress_timestamp;
            hdr.report.egress_timestamp = (bit<32>)standard_metadata.egress_global_timestamp;
            hdr.report.q_delay = hdr.report.egress_timestamp - hdr.report.ingress_timestamp;
            hdr.report.q_depth = (bit<24>)standard_metadata.enq_qdepth;
            hdr.report.departure_timestamp = meta.departure_timestamp;
            hdr.report.return_timestamp = meta.return_timestamp;
            hdr.report.departure_timestamp_e = meta.departure_timestamp_e;
            hdr.report.return_timestamp_e = meta.return_timestamp_e;
            hdr.report.sending_rate = meta.sending_rate;
            hdr.report.data_size = meta.data_size;
            hdr.report.sending_rate_time = meta.sending_rate_time;
            hdr.report.sending_rate_current_time = meta.sending_rate_current_time;
            hdr.report.sending_rate_prev_time = meta.sending_rate_prev_time;
            hdr.report.loss_rate = meta.loss_rate;
            hdr.report.packets_sent = meta.packets_sent;
            hdr.report.packets_received = meta.packets_received;
            hdr.report.interarrival_value = meta.interarrival_value;

            hdr.ipv4.setInvalid();
            hdr.tcp.setInvalid();

            // truncate((bit<32>)18);
        }
    }     
}
