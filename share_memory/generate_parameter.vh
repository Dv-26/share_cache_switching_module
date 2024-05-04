`ifndef SIM
    `define PORT_NUB_TOTAL 8
    `define DATA_WIDTH 7
    `define DEPTH   256

    `define PIPELINE   1
`else
    `define PORT_NUB_TOTAL 4
    `define DATA_WIDTH 6
`endif
