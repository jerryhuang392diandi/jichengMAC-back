`timescale 1ns/1ps

module testbench;

wire clk128;
wire clk125;
wire miiTxClk;
wire miiRxClk;
wire reset;

clockGenerator U_clockGenerator(
  .clk128(clk128),
  .clk125(clk125),
  .miiTxClk(miiTxClk),
  .miiRxClk(miiRxClk),
  .reset(reset));

wire Rx_clk;
wire Tx_clk;
wire hm_Rx_er;
wire hm_Rx_dv;
wire [7:0] hm_Rxd;
wire hm_Tx_en;
wire [7:0] hm_Txd;

reg mode;
reg [200:1]   testcase_name                 ;

ephy U_ephy_hm(
  .GTx_clk(clk125),
  .Rx_clk(Rx_clk),
  .Tx_clk(Tx_clk),
  .Rx_er(hm_Rx_er),
  .Rx_dv(hm_Rx_dv),
  .Rxd(hm_Rxd),
  .Crs(hm_Crs),
  .Col(hm_Col),
  .mode(mode));
  
wire [2:0] mac_speed;

wire   dpram21_wren;
wire   dpram21_rden;

wire [7:0] dpram21_addr;
wire [15:0] dpram21_data_out;

wire [7:0] mac_ca ;  // = dpram21_addr[7:0];
wire [15:0] mac_cd_in ;   //= dpram21_data_out[15:0];
//assign dpram21_data_in = {16'd0, mac_cd_out};
wire mac_csb ;  //= ~(dpram21_rden | dpram21_wren);
wire mac_wrb ;  //= ~dpram21_wren; 
wire [2:0] mac_speed2;
wire [7:0] mac_ca2;
wire [15:0] mac_cd_in2;
wire [15:0] mac_cd_out2;
wire mac_csb2;
wire mac_wrb2;
wire [2:0] mac_speed3;
wire [7:0] mac_ca3;
wire [15:0] mac_cd_in3;
wire [15:0] mac_cd_out3;
wire mac_csb3;
wire mac_wrb3;
reg rdy;
reg mode_switch;

task CHOOSE_MODE;
begin
    // Keep RX FIFO watermarks small; 1000M can otherwise stall in MAC_rx_FF SYS_wait_end.
    U_host_sim.CPU_wr(7'd22,16'd4);
    U_host_sim.CPU_wr(7'd23,16'd2);
    U_host_sim2.CPU_wr(7'd22,16'd4);
    U_host_sim2.CPU_wr(7'd23,16'd2);
    U_host_sim3.CPU_wr(7'd22,16'd4);
    U_host_sim3.CPU_wr(7'd23,16'd2);
    if(mode==0)//100M
    begin
	    U_host_sim.CPU_wr(7'd34,16'h2);
	    U_host_sim2.CPU_wr(7'd34,16'h2);
	    U_host_sim3.CPU_wr(7'd34,16'h2);
    end
	else//1000M
    begin
        U_host_sim.CPU_wr(7'd34,16'h4);	
        U_host_sim2.CPU_wr(7'd34,16'h4);	
        U_host_sim3.CPU_wr(7'd34,16'h4);	
    end
end
endtask

wire [31:0] ff_rx_data_mac;
wire [1:0]   ff_rx_mod_mac;
wire ff_rx_sop_mac;
wire ff_rx_eop_mac;
wire ff_rx_dsav_mac;
wire ff_rx_dval_mac;

// initial 
// begin

// $fdsbDumpfile("test.fsdb");
// $fsdbDumpvars;

// end
wire [5:0] rx_err_mac;
wire [15:0]   mac_cd_out;
wire p1_rx_rdy;
wire p1_ff_tx_rdy;
wire p2_ff_tx_rdy;
wire p3_ff_tx_rdy;
wire p1_tx_ff_uflow;
wire p2_tx_ff_uflow;
wire p3_tx_ff_uflow;
wire p1_ff_tx_septy;
wire p2_ff_tx_septy;
wire p3_ff_tx_septy;

assign p1_rx_rdy = rdy & p2_ff_tx_rdy;

wire hm_Tx_en2;
wire [7:0] hm_Txd2;
wire hm_Tx_er2;
reg hm_Rx_er2;
reg hm_Rx_dv2;
reg [7:0] hm_Rxd2;
wire [31:0] ff_rx_data2;
wire [1:0] ff_rx_mod2;
wire ff_rx_sop2;
wire ff_rx_eop2;
wire ff_rx_dsav2;
wire ff_rx_dval2;
wire [5:0] rx_err2;

wire hm_Tx_en3;
wire [7:0] hm_Txd3;
wire hm_Tx_er3;
reg hm_Rx_er3;
reg hm_Rx_dv3;
reg [7:0] hm_Rxd3;
wire [31:0] ff_rx_data3;
wire [1:0] ff_rx_mod3;
wire ff_rx_sop3;
wire ff_rx_eop3;
wire ff_rx_dsav3;
wire ff_rx_dval3;
wire [5:0] rx_err3;

integer p1_tx_frames;
integer p2_tx_frames;
integer p2_rx_frames;
integer p3_tx_frames;
integer p3_rx_frames;
integer p1_user_rx_frames;
integer p2_user_rx_frames;
integer p3_user_rx_frames;
integer p1_tx_uflow_cnt;
integer p2_tx_uflow_cnt;
integer p3_tx_uflow_cnt;
reg p1_tx_en_d;
reg p2_tx_en_d;
reg p2_rx_dv_d;
reg p3_tx_en_d;
reg p3_rx_dv_d;

always @(posedge Rx_clk or posedge reset)
begin
    if (reset)
    begin
        p1_tx_frames <= 0;
        p2_tx_frames <= 0;
        p2_rx_frames <= 0;
        p3_tx_frames <= 0;
        p3_rx_frames <= 0;
        p1_tx_en_d <= 1'b0;
        p2_tx_en_d <= 1'b0;
        p2_rx_dv_d <= 1'b0;
        p3_tx_en_d <= 1'b0;
        p3_rx_dv_d <= 1'b0;
    end
    else
    begin
        p1_tx_en_d <= hm_Tx_en;
        p2_tx_en_d <= hm_Tx_en2;
        p2_rx_dv_d <= hm_Rx_dv2;
        p3_tx_en_d <= hm_Tx_en3;
        p3_rx_dv_d <= hm_Rx_dv3;
        if (!hm_Tx_en && p1_tx_en_d)
            p1_tx_frames <= p1_tx_frames + 1;
        if (!hm_Tx_en2 && p2_tx_en_d)
            p2_tx_frames <= p2_tx_frames + 1;
        if (!hm_Rx_dv2 && p2_rx_dv_d)
            p2_rx_frames <= p2_rx_frames + 1;
        if (!hm_Tx_en3 && p3_tx_en_d)
            p3_tx_frames <= p3_tx_frames + 1;
        if (!hm_Rx_dv3 && p3_rx_dv_d)
            p3_rx_frames <= p3_rx_frames + 1;
    end
end

always @(posedge clk128 or posedge reset)
begin
    if (reset)
    begin
        p1_user_rx_frames <= 0;
        p2_user_rx_frames <= 0;
        p3_user_rx_frames <= 0;
        p1_tx_uflow_cnt <= 0;
        p2_tx_uflow_cnt <= 0;
        p3_tx_uflow_cnt <= 0;
    end
    else
    begin
        if (ff_rx_dval_mac && ff_rx_eop_mac)
            p1_user_rx_frames <= p1_user_rx_frames + 1;
        if (ff_rx_dval2 && ff_rx_eop2)
            p2_user_rx_frames <= p2_user_rx_frames + 1;
        if (ff_rx_dval3 && ff_rx_eop3)
            p3_user_rx_frames <= p3_user_rx_frames + 1;
        if (p1_tx_ff_uflow)
            p1_tx_uflow_cnt <= p1_tx_uflow_cnt + 1;
        if (p2_tx_ff_uflow)
            p2_tx_uflow_cnt <= p2_tx_uflow_cnt + 1;
        if (p3_tx_ff_uflow)
            p3_tx_uflow_cnt <= p3_tx_uflow_cnt + 1;
    end
end

always @(posedge Rx_clk or posedge reset)
begin
    if (reset)
    begin
        hm_Rx_er2 <= 1'b0;
        hm_Rx_dv2 <= 1'b0;
        hm_Rxd2 <= 8'h00;
        hm_Rx_er3 <= 1'b0;
        hm_Rx_dv3 <= 1'b0;
        hm_Rxd3 <= 8'h00;
    end
    else
    begin
        hm_Rx_er2 <= hm_Tx_er2;
        hm_Rx_dv2 <= hm_Tx_en2;
        hm_Rxd2 <= hm_Txd2;
        hm_Rx_er3 <= hm_Tx_er3;
        hm_Rx_dv3 <= hm_Tx_en3;
        hm_Rxd3 <= hm_Txd3;
    end
end



  
MAC_top MAC_top_inst1
(
  .Reset(reset),
  .Clk_125M(clk125),
  .Clk_user(clk128),
  .Clk_reg(clk128),
  .Speed(mac_speed),
  .ff_rx_rdy(p1_rx_rdy),
  .ff_rx_data(ff_rx_data_mac),
  .ff_rx_mod(ff_rx_mod_mac),
  .ff_rx_sop(ff_rx_sop_mac),
  .ff_rx_eop(ff_rx_eop_mac),
  .ff_rx_dsav(ff_rx_dsav_mac),
  .ff_rx_dval(ff_rx_dval_mac),
  .rx_err(rx_err_mac),
  .ff_tx_data(ff_rx_data3),
  .ff_tx_mod(ff_rx_mod3),
  .ff_tx_sop(ff_rx_sop3),
  .ff_tx_eop(ff_rx_eop3),
  .ff_tx_wren(ff_rx_dval3),
  .ff_tx_err(1'b0),
  .tx_ff_uflow(p1_tx_ff_uflow),
  .ff_tx_rdy(p1_ff_tx_rdy),
  .ff_tx_septy(p1_ff_tx_septy),  
  .Rx_clk(Rx_clk),
  .Tx_clk(Tx_clk),
  .Tx_er(),
  .Tx_en(hm_Tx_en),
  .Txd(hm_Txd),
  .Rx_er(hm_Rx_er),
  .Rx_dv(hm_Rx_dv),
  .Rxd(hm_Rxd),
  .Crs(1'b0),
  .Col(1'b0),
  // .CSB(mac_csb),
  // .WRB(mac_wrb),
  // .CD_in(mac_cd_in),
  // .CD_out(mac_cd_out),
  // .CA(mac_ca)
  .CSB(mac_csb),
  .WRB(mac_wrb),
  .CD_in(mac_cd_in),
  .CD_out(mac_cd_out),
  .CA(mac_ca)  
  
  );
  
  
  MAC_top MAC_top_inst2
(
  .Reset(reset),
  .Clk_125M(clk125),
  .Clk_user(clk128),
  .Clk_reg(clk128),
  .Speed(mac_speed2),
  .ff_rx_rdy(p3_ff_tx_rdy),
  .ff_rx_data(ff_rx_data2),
  .ff_rx_mod(ff_rx_mod2),
  .ff_rx_sop(ff_rx_sop2),
  .ff_rx_eop(ff_rx_eop2),
  .ff_rx_dsav(ff_rx_dsav2),
  .ff_rx_dval(ff_rx_dval2),
  .rx_err(rx_err2),
  .ff_tx_data(ff_rx_data_mac),
  .ff_tx_mod(ff_rx_mod_mac),
  .ff_tx_sop(ff_rx_sop_mac),
  .ff_tx_eop(ff_rx_eop_mac),
  .ff_tx_wren(ff_rx_dval_mac),
  .ff_tx_err(1'b0),
  .tx_ff_uflow(p2_tx_ff_uflow),
  .ff_tx_rdy(p2_ff_tx_rdy),
  .ff_tx_septy(p2_ff_tx_septy),  
  .Rx_clk(Rx_clk),
  .Tx_clk(Tx_clk),
  .Tx_er(hm_Tx_er2),
  .Tx_en(hm_Tx_en2),
  .Txd(hm_Txd2),
  .Rx_er(hm_Rx_er2),
  .Rx_dv(hm_Rx_dv2),
  .Rxd(hm_Rxd2),
  .Crs(1'b0),
  .Col(1'b0),
  // .CSB(mac_csb),
  // .WRB(mac_wrb),
  // .CD_in(mac_cd_in),
  // .CD_out(mac_cd_out),
  // .CA(mac_ca)
  .CSB(mac_csb2),
  .WRB(mac_wrb2),
  .CD_in(mac_cd_in2),
  .CD_out(mac_cd_out2),
  .CA(mac_ca2)  
  
  );
  
    MAC_top MAC_top_inst3
(
  .Reset(reset),
  .Clk_125M(clk125),
  .Clk_user(clk128),
  .Clk_reg(clk128),
  .Speed(mac_speed3),
  .ff_rx_rdy(p1_ff_tx_rdy),
  .ff_rx_data(ff_rx_data3),
  .ff_rx_mod(ff_rx_mod3),
  .ff_rx_sop(ff_rx_sop3),
  .ff_rx_eop(ff_rx_eop3),
  .ff_rx_dsav(ff_rx_dsav3),
  .ff_rx_dval(ff_rx_dval3),
  .rx_err(rx_err3),
  .ff_tx_data(ff_rx_data2),
  .ff_tx_mod(ff_rx_mod2),
  .ff_tx_sop(ff_rx_sop2),
  .ff_tx_eop(ff_rx_eop2),
  .ff_tx_wren(ff_rx_dval2),
  .ff_tx_err(1'b0),
  .tx_ff_uflow(p3_tx_ff_uflow),
  .ff_tx_rdy(p3_ff_tx_rdy),
  .ff_tx_septy(p3_ff_tx_septy),  
  .Rx_clk(Rx_clk),
  .Tx_clk(Tx_clk),
  .Tx_er(hm_Tx_er3),
  .Tx_en(hm_Tx_en3),
  .Txd(hm_Txd3),
  .Rx_er(hm_Rx_er3),
  .Rx_dv(hm_Rx_dv3),
  .Rxd(hm_Rxd3),
  .Crs(1'b0),
  .Col(1'b0),
  // .CSB(mac_csb),
  // .WRB(mac_wrb),
  // .CD_in(mac_cd_in),
  // .CD_out(mac_cd_out),
  // .CA(mac_ca)
  .CSB(mac_csb3),
  .WRB(mac_wrb3),
  .CD_in(mac_cd_in3),
  .CD_out(mac_cd_out3),
  .CA(mac_ca3)  
  
  );
  


data_cmp U_data_cmp(
	.Rx_clk(Rx_clk)	, 
	.Tx_clk(Tx_clk)	, 
	.Tx_er ()	, 
	.Tx_en (hm_Tx_en)	, 
	.Txd   (hm_Txd)	,
	.Rx_er (hm_Rx_er)	, 
	.Rx_dv (hm_Rx_dv)	, 
	.Rxd   (hm_Rxd)	,
    .reset (reset),
    .testcase_name(testcase_name),	
	.mode  (mode)	
	);
	
host_sim U_host_sim(
.Reset	               			(reset	                  	),    
.Clk_reg                  		(clk128                 	), 
.CSB                            (mac_csb                        ),
.WRB                            (mac_wrb                        ),
.CD_in                          (mac_cd_in                      ),
.CD_out                         (mac_cd_out                     ),
.CPU_init_end                   (CPU_init_end               ),
.CA                             (mac_ca                         )
 
);	

host_sim U_host_sim2(
.Reset	               			(reset	                  	),    
.Clk_reg                  		(clk128                 	), 
.CSB                            (mac_csb2                       ),
.WRB                            (mac_wrb2                       ),
.CD_in                          (mac_cd_in2                     ),
.CD_out                         (mac_cd_out2                    ),
.CPU_init_end                   (CPU_init_end2                  ),
.CA                             (mac_ca2                        )
 
);	

host_sim U_host_sim3(
.Reset	               			(reset	                  	),    
.Clk_reg                  		(clk128                 	), 
.CSB                            (mac_csb3                       ),
.WRB                            (mac_wrb3                       ),
.CD_in                          (mac_cd_in3                     ),
.CD_out                         (mac_cd_out3                    ),
.CPU_init_end                   (CPU_init_end3                  ),
.CA                             (mac_ca3                        )
 
);	
	
  
integer i = 0;
integer len = 0;
reg [15:0] data_cnt = 16'b1;
initial
begin
	U_host_sim.CPU_init;
	U_host_sim2.CPU_init;
	U_host_sim3.CPU_init;
	rdy=1'b0;
	mode=1'b0;
	mode_switch=0;
	
	// U_host_sim.CPU_wr(7'd33,16'h1);
	
	#800;
	rdy=1'b1;
	`include "../testcase/0100000064.v"
	$display("PORT_COUNTS %s p1_tx=%0d p2_tx=%0d p2_rx=%0d p3_tx=%0d p3_rx=%0d",
	         testcase_name, p1_tx_frames, p2_tx_frames, p2_rx_frames, p3_tx_frames, p3_rx_frames);
	$display("USER_COUNTS %s p1_rx=%0d p2_rx=%0d p3_rx=%0d uflow=%0d/%0d/%0d",
	         testcase_name, p1_user_rx_frames, p2_user_rx_frames, p3_user_rx_frames,
	         p1_tx_uflow_cnt, p2_tx_uflow_cnt, p3_tx_uflow_cnt);
	`include "../testcase/0100000065.v"
	$display("PORT_COUNTS %s p1_tx=%0d p2_tx=%0d p2_rx=%0d p3_tx=%0d p3_rx=%0d",
	         testcase_name, p1_tx_frames, p2_tx_frames, p2_rx_frames, p3_tx_frames, p3_rx_frames);
	$display("USER_COUNTS %s p1_rx=%0d p2_rx=%0d p3_rx=%0d uflow=%0d/%0d/%0d",
	         testcase_name, p1_user_rx_frames, p2_user_rx_frames, p3_user_rx_frames,
	         p1_tx_uflow_cnt, p2_tx_uflow_cnt, p3_tx_uflow_cnt);
	// `include "../testcase/0100000066.v"
	// `include "../testcase/0100000067.v"
	// `include "../testcase/0100000068.v"
	
	#10000;

	$stop;
end

// dump fsdb file for debussy
// initial
// begin
  // $fsdbDumpfile("mac.fsdb");
  // $fsdbDumpvars;
// end


/* initial
begin
//    $dumpfile("mac.vcd");
//    $dumpvars; 
    $vcdpluson;
    #12000000;
    $finish;
end */

endmodule

