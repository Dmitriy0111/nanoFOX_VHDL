/*
*  File            :   nf_uart_transmitter_tb.sv
*  Autor           :   Vlasov D.V.
*  Data            :   2019.04.25
*  Language        :   SystemVerilog
*  Description     :   This testbench for uart transmitter module
*  Copyright(c)    :   2019 Vlasov D.V.
*/

module nf_uart_transmitter_tb ();
    
    timeprecision   1ns;
    timeunit        1ns;

    localparam      T = 20;
    localparam      rst_delay  = 7;
    localparam      work_freq  = 50_000_000;
    localparam      uart_speed = 115200;

    // reset and clock
    bit     [0  : 0]    clk;        // clk
    bit     [0  : 0]    resetn;     // resetn
    // controller side interface
    logic   [0  : 0]    tr_en;      // transmitter enable
    logic   [15 : 0]    comp;       // compare input for setting baudrate
    logic   [7  : 0]    tx_data;    // data for transfer
    logic   [0  : 0]    req;        // request signal
    logic   [0  : 0]    req_ack;    // acknowledgent signal
    // uart tx side
    logic   [0  : 0]    uart_tx;    // UART tx wire

    nf_uart_transmitter
    nf_uart_transmitter_0
    (
        // reset and clock
        .clk        ( clk       ),  // clk
        .resetn     ( resetn    ),  // resetn
        // controller side interface
        .tr_en      ( tr_en     ),  // transmitter enable
        .comp       ( comp      ),  // compare input for setting baudrate
        .tx_data    ( tx_data   ),  // data for transfer
        .req        ( req       ),  // request signal
        .req_ack    ( req_ack   ),  // acknowledgent signal
        // uart tx side
        .uart_tx    ( uart_tx   )   // UART tx wire
    );

    task send_char(logic [7 : 0] c);
        tx_data = c;
        @(posedge clk);
        req = '1;
        @(posedge clk);
        req = '0;
    endtask : send_char

    task wait_req_ack();
        @(posedge req_ack);
    endtask : wait_req_ack

    task send_message(string message);
        integer i;
        i=0;
        for(i = 0; i < message.len(); i++)
        begin
            send_char(message[i]);
            $display("Start send char = %c, time = %tns",message[i],$time);
            wait_req_ack();
            $display("End   send char = %c, time = %tns",message[i],$time);
        end
    endtask : send_message

    // clock generation
    initial
    begin
        $display("Clock generation start!");
        forever #( T / 2 ) clk = ~ clk;
    end
    // reset generation
    initial
    begin
        $display("Reset is in active state!");
        repeat(rst_delay) @(posedge clk);
        resetn = '1;
        $display("Reset is in inactive state!");
    end
    // other logic
    initial
    begin
        comp = work_freq / uart_speed;
        tr_en = '0;
        tx_data = "H";
        req = '0;
        @(posedge resetn);
        tr_en = '1;
        repeat(10) @(posedge clk);
        send_message("Hello World!");
        $stop;
    end

endmodule : nf_uart_transmitter_tb