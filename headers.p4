const bit<16> TYPE_IPV4 = 0x0800;
const bit<8> TYPE_TCP = 6;
const bit<8> TYPE_UDP = 17;
const bit<16> TYPE_CUSTOM = 2001;
const bit<8> TYPE_CUSTOM_I = 0xFF;


#define MAX_HOPS 8
#define PKT_TYPE_SEQ true
#define PKT_TYPE_ACK false

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<16> port_t;
typedef bit<8> switch_ID_t;

typedef bit<5> tcp_flags_t;
const tcp_flags_t TCP_FLAGS_F = 1;
const tcp_flags_t TCP_FLAGS_S = 2;
const tcp_flags_t TCP_FLAGS_R = 4;
const tcp_flags_t TCP_FLAGS_P = 8;
const tcp_flags_t TCP_FLAGS_A = 16;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header udp_t {
    port_t srcPort;
    port_t dstPort;
    bit<16> len;
    bit<16> checksum;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<3>  ecn;
    bit<5>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header report_t {
    bit<8>  switch_ID;
    // bit<32> rtt;
    // bit<32> rtt_e;
    bit<48> ingress_timestamp;
    bit<48> egress_timestamp;
    bit<48> q_delay;
    bit<24> q_depth;
    // bit<32> departure_timestamp;
    // bit<32> return_timestamp;
    // bit<32> departure_timestamp_e;
    // bit<32> return_timestamp_e;
    // bit<32> sending_rate;
    bit<32> sending_rate_time;
    bit<32> sending_rate_current_time;
    bit<32> sending_rate_prev_time;
    // bit<32> loss_rate;
    bit<32> packets_sent;
    bit<32> data_sent;
    bit<32> packets_received;
    bit<32> data_received;
    bit<48> interarrival_value;
}

struct parser_metadata_t {
   bit<16> remaining;
}

struct metadata {
    @field_list(0)
    bit<8> switch_ID;
    // @field_list(0)
    // bit<32> rtt_sample;
    // @field_list(0)
    // bit<32> rtt_sample_e;
    @field_list(0)
    bit<48> ingress_timestamp;
    @field_list(0)
    bit<48> egress_timestamp;
    @field_list(0)
    bit<48> q_delay;
    @field_list(0)
    bit<24> q_depth;
    // @field_list(0)
    // bit<32> departure_timestamp;
    // @field_list(0)
    // bit<32> return_timestamp;
    // @field_list(0)
    // bit<32> departure_timestamp_e;
    // @field_list(0)
    // bit<32> return_timestamp_e;
    // @field_list(0)
    // bit<32> sending_rate;
    @field_list(0)
    bit<32> sending_rate_time;
    @field_list(0)
    bit<32> sending_rate_current_time;
    @field_list(0)
    bit<32> sending_rate_prev_time;
    // @field_list(0)
    // bit<32> loss_rate;
    @field_list(0)
    bit<32> packets_sent;
    @field_list(0)
    bit<32> data_sent;
    @field_list(0)
    bit<32> packets_received;
    @field_list(0)
    bit<32> data_received;
    @field_list(0)
    bit<48> interarrival_value;
    // @field_list(0)
    // bit<16> sent_bytes_i;
    // @field_list(0)
    // bit<16> sent_bytes_e;
    bit<16> flow_id;
    // bool pkt_type;
    // bit<32> expected_ack;
    // bit<32> pkt_signature;

    parser_metadata_t parser_metadata;
}

struct headers {
    ethernet_t                  ethernet;
    ipv4_t                      ipv4;
    tcp_t                       tcp;
    udp_t                       udp;
    report_t                    report;
}