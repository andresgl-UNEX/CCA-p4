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
        // meta.switch_ID = ID;
        // meta.ingress_timestamp = (bit<32>)standard_metadata.ingress_global_timestamp;
        // meta.sent_bytes_i = hdr.ipv4.totalLen;
    }
   
    action drop() {
       mark_to_drop(standard_metadata);
    }

    // action compute_flow_id() {
    //     hash(
    //         meta.flow_id, 
    //         HashAlgorithm.crc16, 
    //         (bit<1>)0, 
    //         {
    //         hdr.ipv4.srcAddr,
    //         hdr.ipv4.dstAddr,
    //         hdr.ipv4.protocol,
    //         hdr.tcp.srcPort,
    //         hdr.tcp.dstPort
    //         }, 
    //         (bit<16>) 65535
    //     );
    // }

    // action mark_SEQ() {
    //     meta.pkt_type = PKT_TYPE_SEQ;
    // }

    // action mark_ACK() {
    //     meta.pkt_type = PKT_TYPE_ACK;
    // }

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
            // hdr.ipv4.dstAddr: exact;
            hdr.ethernet.dstAddr: exact;
        }
        actions = {
            forward;
            drop;
        }
        size = 1024;
        default_action = drop();
    }

    // table get_packet_type {
    //     key = {
    //         hdr.tcp.flags: ternary;
    //         hdr.ipv4.totalLen: range;
    //     }
    //     actions = {
    //         mark_SEQ;
    //         mark_ACK;
    //         drop;
    //     }
    //     default_action = mark_SEQ();
    //     const entries = {
    //         (TCP_FLAGS_S, _) : mark_SEQ();
    //         (TCP_FLAGS_S + TCP_FLAGS_A, _) : mark_ACK();
    //         (TCP_FLAGS_A, 0..80) : mark_ACK();
    //         (TCP_FLAGS_A + TCP_FLAGS_P, 0..80) : mark_ACK();
    //         (_, 100..1600) : mark_SEQ();
    //         (TCP_FLAGS_R, _) : drop();
    //         (TCP_FLAGS_F, _) : drop();
    //     }
    // }

    // action compute_expected_ack() {
    //     meta.expected_ack = hdr.tcp.seqNo + ((bit<32>)(hdr.ipv4.totalLen - 
    //         (((bit<16>)hdr.ipv4.ihl + ((bit<16>)hdr.tcp.dataOffset)) * 16w4)));
    //     if(hdr.tcp.flags == TCP_FLAGS_S) {
    //         meta.expected_ack = meta.expected_ack + 1;
    //     }
    // }

    // action get_pkt_signature_SEQ() {
    //     hash (
    //         meta.pkt_signature,
    //         HashAlgorithm.crc32,
    //         (bit<1>)0,
    //         {
    //             hdr.ipv4.srcAddr,
    //             hdr.ipv4.dstAddr,
    //             hdr.tcp.srcPort,
    //             hdr.tcp.dstPort,
    //             meta.expected_ack
    //         },
    //         (bit<32>)1048576
    //     );
    // }

    // action get_pkt_signature_ACK() {
    //     hash (
    //         meta.pkt_signature,
    //         HashAlgorithm.crc32,
    //         (bit<1>)0,
    //         {
    //             hdr.ipv4.dstAddr,
    //             hdr.ipv4.srcAddr,
    //             hdr.tcp.dstPort,
    //             hdr.tcp.srcPort,
    //             hdr.tcp.ackNo
    //         },
    //         (bit<32>)1048576
    //     );
    // }

    register<bit<32>>(1048576) bytes_transmitted;  // Para almacenar los bytes transmitidos por flujo
    register<bit<32>>(1048576) sending_rate_prev_time;
    // register<bit<32>>(1048576) total_packets_sent; // Para almacenar los paquetes enviados por flujo
    // register<bit<32>>(1048576) total_packets_received; // Para almacenar los paquetes recibidos por flujo

    // action update_sending_rate() {
    //     bit<32> bytes_transmitted_flow;
    //     bit<32> current_time;
    //     bit<32> prev_time;
        
    //     bytes_transmitted.read(bytes_transmitted_flow, (bit<32>)meta.flow_id);
    //     bytes_transmitted_flow = bytes_transmitted_flow + (bit<32>)hdr.ipv4.totalLen;
    //     bytes_transmitted.write((bit<32>)meta.flow_id, bytes_transmitted_flow);

    //     current_time = (bit<32>)standard_metadata.ingress_global_timestamp;
    //     meta.sending_rate = bytes_transmitted_flow;
    //     sending_rate_prev_time.read(prev_time, (bit<32>)meta.flow_id);
    //     meta.sending_rate_time = (bit<32>)standard_metadata.ingress_global_timestamp - prev_time;
    //     meta.sending_rate_prev_time = prev_time;
    //     meta.sending_rate_current_time = current_time;
    //     sending_rate_prev_time.write((bit<32>)meta.flow_id, current_time);
    // }

    action update_sending_rate() {
        bit<32> bytes_transmitted_flow;
        bit<32> current_time;
        bit<32> prev_time;
        bit<32> time_diff;

        // Leer el número total de bytes transmitidos para este flujo
        bytes_transmitted.read(bytes_transmitted_flow, (bit<32>)meta.flow_id);
        bytes_transmitted_flow = bytes_transmitted_flow + (bit<32>)hdr.ipv4.totalLen;
        bytes_transmitted.write((bit<32>)meta.flow_id, bytes_transmitted_flow);

        // Leer el tiempo previo del flujo
        sending_rate_prev_time.read(prev_time, (bit<32>)meta.flow_id);
        current_time = (bit<32>)standard_metadata.ingress_global_timestamp;

        // Calcular la diferencia de tiempo
        time_diff = current_time - prev_time;

        if (time_diff > 0) {
            // Actualizar los metadatos con los datos para el sending rate
            meta.data_sent = bytes_transmitted_flow * 8;  // Convertir bytes a bits
            meta.sending_rate_time = time_diff;

            // (Opcional) Calcular y almacenar el sending rate si se requiere en esta fase:
            // meta.sending_rate = (meta.data_sent / meta.sending_rate_time);  // bits por nanosegundo
        }

        // Actualizar el timestamp previo
        sending_rate_prev_time.write((bit<32>)meta.flow_id, current_time);
    }


    // action update_loss_rate() {
    //     bit<32> packets_sent;
    //     bit<32> packets_received;

    //     total_packets_sent.read(packets_sent, (bit<32>)meta.flow_id);
    //     total_packets_received.read(packets_received, (bit<32>)meta.flow_id);

    //     if (packets_sent != 0) {
    //         meta.loss_rate = (packets_sent - packets_received) * 100;
    //         meta.packets_sent = packets_sent;
    //         meta.packets_received = packets_received;
    //     } else {
    //         meta.loss_rate = 0;
    //     }

    //     total_packets_sent.write((bit<32>)meta.flow_id, packets_sent + 1);
    //     total_packets_received.write((bit<32>)meta.flow_id, packets_received + 1);
    // }

    // register<bit<32>>(1048576) last_timestamp_reg_rtt;

    apply {
        if(hdr.ipv4.isValid()){
            forwarding.apply();

            get_interarrival_time();
            meta.interarrival_value = interarrival_value;

            update_sending_rate();
            // update_loss_rate();

            // if(hdr.tcp.isValid()) {
            //     compute_flow_id();
            //     get_packet_type.apply();

            //     if(meta.pkt_type == PKT_TYPE_SEQ) {
            //         compute_expected_ack();
            //         get_pkt_signature_SEQ();
            //         last_timestamp_reg_rtt.write((bit<32>)meta.pkt_signature,
            //         (bit<32>)standard_metadata.ingress_global_timestamp);
            //     } else {
            //         get_pkt_signature_ACK();
            //         bit<32> extracted_ts;
            //         last_timestamp_reg_rtt.read(extracted_ts, (bit<32>)meta.pkt_signature);
            //         meta.rtt_sample = (bit<32>)standard_metadata.ingress_global_timestamp - extracted_ts;
            //         meta.return_timestamp = (bit<32>)standard_metadata.ingress_global_timestamp;
            //         meta.departure_timestamp = extracted_ts;
            //         clone_preserving_field_list(CloneType.I2E, 5, 0);
            //     }

            //     update_sending_rate();
            //     update_loss_rate();
            // }

            // https://github.com/gomezgaona/mininet-topologies.git

            // CLONAR LA LOGICA A EGRESS

            // MOSTRAR ipv4.hdr.totalLen

            // UTILIZAR UNA FLAG PARA VER QUE PAQUETES SON NORMALES Y CUALES VIENEN DE VUELTA PARA 
            // EL CALCULO DEL RTT
        }
    }
}
