/*
*  File            :   nf_uart_receiver_tb.sv
*  Autor           :   Vlasov D.V.
*  Data            :   2019.04.25
*  Language        :   SystemVerilog
*  Description     :   This testbench for uart receiver module
*  Copyright(c)    :   2019 Vlasov D.V.
*/

module nf_uart_receiver_tb ();
    
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
    logic   [0  : 0]    rec_en;     // receiver enable
    logic   [15 : 0]    comp;       // compare input for setting baudrate
    logic   [7  : 0]    rx_data;    // received data
    logic   [0  : 0]    rx_valid;   // receiver data valid
    logic   [0  : 0]    rx_val_set; // receiver data valid set
    // uart tx side
    logic   [0  : 0]    uart_rx;    // UART rx wire

    nf_uart_receiver
    nf_uart_receiver_0
    (
        // reset and clock
        .clk        ( clk           ),  // clk
        .resetn     ( resetn        ),  // resetn
        // controller side interface
        .rec_en     ( rec_en        ),  // receiver enable
        .comp       ( comp          ),  // compare input for setting baudrate
        .rx_data    ( rx_data       ),  // received data
        .rx_valid   ( rx_valid      ),  // receiver data valid
        .rx_val_set ( rx_val_set    ),  // receiver data valid set
        // uart tx side
        .uart_rx    ( uart_rx       )   // UART rx wire
    );

    // task for sending symbol over uart to receive module
    task send_uart_symbol( logic [7 : 0] symbol );
        // generate 'start'
        uart_rx = '0;
        repeat( work_freq / uart_speed ) @(posedge clk);
        // generate transaction
        for( integer i = 0 ; i < 8 ; i ++ )
        begin
            uart_rx = symbol[i];
            repeat( work_freq / uart_speed ) @(posedge clk);
        end
        // generate 'stop'
        uart_rx = '1;
        repeat( work_freq / uart_speed ) @(posedge clk);
    endtask : send_uart_symbol
    // task for sending message over uart to receive module
    task send_uart_message( string message );
        for( int i=0; i<message.len(); i++ )
        begin
            send_uart_symbol(message[i]);
            rx_val_set='1;
            @(posedge clk);
            rx_val_set='0;
            $display("Received data = %c, %t ns", rx_data, $time);
        end
    endtask : send_uart_message

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
        rec_en = '0;
        rx_val_set = '0;
        @(posedge resetn);
        rec_en = '1;
        repeat(10) @(posedge clk);
        send_uart_message("Hello World!");
        $stop;
    end

endmodule : nf_uart_receiver_tb