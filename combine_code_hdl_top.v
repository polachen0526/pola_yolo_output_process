
`timescale 1 ns / 1 ps

	module CNN_Yolo_Outstanding_v1_0 #
	(
		// Users to add parameters here
        parameter C_S_AXI_DATA_WIDTH = 32,
        parameter C_M_AXI_ID_WIDTH	    = 1,
        parameter C_M_AXI_ADDR_WIDTH	= 32,
        parameter C_M_AXI_DATA_WIDTH	= 128,
        parameter C_M_AXI_AWUSER_WIDTH	= 1,
        parameter C_M_AXI_ARUSER_WIDTH	= 1,
        parameter C_M_AXI_WUSER_WIDTH	= 1,
        parameter C_M_AXI_RUSER_WIDTH	= 1,
        parameter C_M_AXI_BUSER_WIDTH	= 1,
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 6
	)
	(
		// Users to add ports here
        // M_AXI-Full
        input                                    M_AXI_ACLK,
        input                                    M_AXI_ARESETN,
        //----------------------------------------------------------------------------------
        //  (AW) Channel
        //----------------------------------------------------------------------------------
        input                                    M_AXI_AWREADY,
        output  [C_M_AXI_ID_WIDTH-1 : 0]         M_AXI_AWID,     //Unused
        output  [C_M_AXI_ADDR_WIDTH-1 : 0]       M_AXI_AWADDR,   
        output  [7 : 0]                          M_AXI_AWLEN,
        output  [2 : 0]                          M_AXI_AWSIZE,   //Unused
        output  [1 : 0]                          M_AXI_AWBURST,  //Unused
        output                                   M_AXI_AWLOCK,   //Unused
        output  [3 : 0]                          M_AXI_AWCACHE,  //Unused
        output  [2 : 0]                          M_AXI_AWPROT,   //Unused
        output  [3 : 0]                          M_AXI_AWQOS,    //Unused
        output  [C_M_AXI_AWUSER_WIDTH-1 : 0]     M_AXI_AWUSER,   //Unused
        output                                   M_AXI_AWVALID,

        //----------------------------------------------------------------------------------
        //  (W) Channel
        //----------------------------------------------------------------------------------
        input                                    M_AXI_WREADY,
        output  [C_M_AXI_DATA_WIDTH-1 : 0]       M_AXI_WDATA,
        output  [C_M_AXI_DATA_WIDTH/8-1 : 0]     M_AXI_WSTRB,
        output                                   M_AXI_WLAST,
        output  [C_M_AXI_WUSER_WIDTH-1 : 0]      M_AXI_WUSER,    //Unused
        output                                   M_AXI_WVALID,

        //----------------------------------------------------------------------------------
        //  (B) Channel
        //----------------------------------------------------------------------------------
        input  [C_M_AXI_ID_WIDTH-1 : 0]          M_AXI_BID,      //Unused
        input  [1 : 0]                           M_AXI_BRESP,
        input  [C_M_AXI_BUSER_WIDTH-1 : 0]       M_AXI_BUSER,    //Unused
        input                                    M_AXI_BVALID,
        output                                   M_AXI_BREADY,
        
        //----------------------------------------------------------------------------------
        //  (AR) Channel
        //----------------------------------------------------------------------------------
        input                                    M_AXI_ARREADY, // ready
        output  [C_M_AXI_ID_WIDTH-1 : 0]         M_AXI_ARID,    //0
        output  wire [C_M_AXI_ADDR_WIDTH-1 : 0]  M_AXI_ARADDR,  // addr
        output  wire [7 : 0]                     M_AXI_ARLEN,   // 128 bits
        output  [2 : 0]                          M_AXI_ARSIZE,
        output  [1 : 0]                          M_AXI_ARBURST,
        output                                   M_AXI_ARLOCK,
        output  [3 : 0]                          M_AXI_ARCACHE,
        output  [2 : 0]                          M_AXI_ARPROT,
        output  [3 : 0]                          M_AXI_ARQOS,
        output  [C_M_AXI_ARUSER_WIDTH-1 : 0]     M_AXI_ARUSER,
        output  wire                             M_AXI_ARVALID, // same as ready, but just for one cycle

        //----------------------------------------------------------------------------------
        //  (R) Channel
        //----------------------------------------------------------------------------------
        input  [C_M_AXI_ID_WIDTH-1 : 0]          M_AXI_RID,     //
        input  [C_M_AXI_DATA_WIDTH-1 : 0]        M_AXI_RDATA,   //Dram -> Sram Data
        input  [1 : 0]                           M_AXI_RRESP,   // feedback good or bad
        input                                    M_AXI_RLAST,   // last value
        input  [C_M_AXI_RUSER_WIDTH-1 : 0]       M_AXI_RUSER,
        input                                    M_AXI_RVALID,  // when valid is High , read data is effective
        output wire                              M_AXI_RREADY,   // ready to start reading
        output                                   IRQ,
        output                                   s_axi_start_output,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready,


        output   [31:0]                     HARDWARE_VERSION,


    output   [1:0]                          DEBUG_INPUT_state,
                                            DEBUG_INPUT_start_valid_buffer,
    output   [2:0]                          DEBUG_INPUT_state_input_ctrl,
    output                                  DEBUG_Master_Output_Finish,
                                            DEBUG_Compute_Finish,
                                            DEBUG_For_State_Finish,
                                            DEBUG_Pad_Start_OBUF_FINISH,
                                            DEBUG_CONV_FLAG,
                                            DEBUG_IRQ_TO_MASTER_CTRL,
                                            DEBUG_have_pool_ing,
                                            DEBUG_ready_A,
                                            DEBUG_ready_B,
                                            DEBUG_start_A,
                                            DEBUG_start_B,
    output       [1:0]                      DEBUG_obuf_state,
                                            DEBUG_obuf_pool_s,
                                            DEBUG_obuf_finish_state,
    output                                  DEBUG_obuf_rst,
    output [5:0]                            DEBUF_Layer_selc,
    output [2:0]                            DEBUG_Layer_type,
	output [31:0]                           DEBUG_cycle_data

	);

    wire s_axi_start_sel;
    wire s_axi_start;
    wire [C_S00_AXI_DATA_WIDTH-1 : 0] s_axi_inst_0;
    wire [C_S00_AXI_DATA_WIDTH-1 : 0] s_axi_inst_1;
    wire [C_S00_AXI_DATA_WIDTH-1 : 0] s_axi_inst_2;
    wire [C_S00_AXI_DATA_WIDTH-1 : 0] s_axi_inst_3;
    wire [C_S00_AXI_DATA_WIDTH-1 : 0] s_axi_inst_4;
    wire [C_S00_AXI_DATA_WIDTH-1 : 0] s_axi_Rerror_addr;
    wire [C_S00_AXI_DATA_WIDTH-1 : 0] s_axi_Werror_addr;
    wire s_axi_Rerror;
    wire [1 : 0] s_axi_Werror;

	wire [C_S_AXI_DATA_WIDTH-1 : 0] layer_selc;		//slv_reg10
	wire [C_S_AXI_DATA_WIDTH-1 : 0] cycle_data_selc;	//slv_reg11
	wire [C_S_AXI_DATA_WIDTH-1 : 0] cycle_data;		//slv_reg12

    
    //----------------------------------------------------------------------------------
    //  (AW) Channel control two axi
    //----------------------------------------------------------------------------------
    wire   [C_M_AXI_ID_WIDTH-1 : 0]                 M_AXI_AWID_CNN      ,   M_AXI_AWID_yolo_output_process      ;
    wire   [C_M_AXI_ADDR_WIDTH-1 : 0]               M_AXI_AWADDR_CNN    ,   M_AXI_AWADDR_yolo_output_process    ;
    wire   [7 : 0]                                  M_AXI_AWLEN_CNN     ,   M_AXI_AWLEN_yolo_output_process     ;
    wire   [2 : 0]                                  M_AXI_AWSIZE_CNN    ,   M_AXI_AWSIZE_yolo_output_process    ;
    wire   [1 : 0]                                  M_AXI_AWBURST_CNN   ,   M_AXI_AWBURST_yolo_output_process   ;
    wire                                            M_AXI_AWLOCK_CNN    ,   M_AXI_AWLOCK_yolo_output_process    ;
    wire   [3 : 0]                                  M_AXI_AWCACHE_CNN   ,   M_AXI_AWCACHE_yolo_output_process   ;
    wire   [2 : 0]                                  M_AXI_AWPROT_CNN    ,   M_AXI_AWPROT_yolo_output_process    ;
    wire   [3 : 0]                                  M_AXI_AWQOS_CNN     ,   M_AXI_AWQOS_yolo_output_process     ;
    wire   [C_M_AXI_AWUSER_WIDTH-1 : 0]             M_AXI_AWUSER_CNN    ,   M_AXI_AWUSER_yolo_output_process    ;
    wire                                            M_AXI_AWVALID_CNN   ,   M_AXI_AWVALID_yolo_output_process   ;
    assign M_AXI_AWID       =   (s_axi_start_sel) ? M_AXI_AWID_CNN      :   M_AXI_AWID_yolo_output_process      ;
    assign M_AXI_AWADDR     =   (s_axi_start_sel) ? M_AXI_AWADDR_CNN    :   M_AXI_AWADDR_yolo_output_process    ;
    assign M_AXI_AWLEN      =   (s_axi_start_sel) ? M_AXI_AWLEN_CNN     :   M_AXI_AWLEN_yolo_output_process     ; 
    assign M_AXI_AWSIZE     =   (s_axi_start_sel) ? M_AXI_AWSIZE_CNN    :   M_AXI_AWSIZE_yolo_output_process    ; 
    assign M_AXI_AWBURST    =   (s_axi_start_sel) ? M_AXI_AWBURST_CNN   :   M_AXI_AWBURST_yolo_output_process   ; 
    assign M_AXI_AWLOCK     =   (s_axi_start_sel) ? M_AXI_AWLOCK_CNN    :   M_AXI_AWLOCK_yolo_output_process    ; 
    assign M_AXI_AWCACHE    =   (s_axi_start_sel) ? M_AXI_AWCACHE_CNN   :   M_AXI_AWCACHE_yolo_output_process   ; 
    assign M_AXI_AWPROT     =   (s_axi_start_sel) ? M_AXI_AWPROT_CNN    :   M_AXI_AWPROT_yolo_output_process    ; 
    assign M_AXI_AWQOS      =   (s_axi_start_sel) ? M_AXI_AWQOS_CNN     :   M_AXI_AWQOS_yolo_output_process     ; 
    assign M_AXI_AWUSER     =   (s_axi_start_sel) ? M_AXI_AWUSER_CNN    :   M_AXI_AWUSER_yolo_output_process    ; 
    assign M_AXI_AWVALID    =   (s_axi_start_sel) ? M_AXI_AWVALID_CNN   :   M_AXI_AWVALID_yolo_output_process   ; 

    //----------------------------------------------------------------------------------
    //  (W) Channel control two axi
    //----------------------------------------------------------------------------------
    wire   [C_M_AXI_DATA_WIDTH-1 : 0]               M_AXI_WDATA_CNN     ,   M_AXI_WDATA_yolo_output_process     ;
    wire   [C_M_AXI_DATA_WIDTH/8-1 : 0]             M_AXI_WSTRB_CNN     ,   M_AXI_WSTRB_yolo_output_process     ;
    wire                                            M_AXI_WLAST_CNN     ,   M_AXI_WLAST_yolo_output_process     ;
    wire   [C_M_AXI_WUSER_WIDTH-1 : 0]              M_AXI_WUSER_CNN     ,   M_AXI_WUSER_yolo_output_process     ;
    wire                                            M_AXI_WVALID_CNN    ,   M_AXI_WVALID_yolo_output_process    ;
    assign M_AXI_WDATA      =   (s_axi_start_sel) ? M_AXI_WDATA_CNN     :   M_AXI_WDATA_yolo_output_process     ;
    assign M_AXI_WSTRB      =   (s_axi_start_sel) ? M_AXI_WSTRB_CNN     :   M_AXI_WSTRB_yolo_output_process     ;
    assign M_AXI_WLAST      =   (s_axi_start_sel) ? M_AXI_WLAST_CNN     :   M_AXI_WLAST_yolo_output_process     ;
    assign M_AXI_WUSER      =   (s_axi_start_sel) ? M_AXI_WUSER_CNN     :   M_AXI_WUSER_yolo_output_process     ;
    assign M_AXI_WVALID     =   (s_axi_start_sel) ? M_AXI_WVALID_CNN    :   M_AXI_WVALID_yolo_output_process    ;

    //----------------------------------------------------------------------------------
    //  (B) Channel control two axi
    //----------------------------------------------------------------------------------
    wire                                            M_AXI_BREADY_CNN    ,   M_AXI_BREADY_yolo_output_process    ;
    assign M_AXI_BREADY     =   (s_axi_start_sel) ? M_AXI_BREADY_CNN    :   M_AXI_BREADY_yolo_output_process    ;

    //----------------------------------------------------------------------------------
    //  (AR) Channel control two axi
    //----------------------------------------------------------------------------------
    wire   [C_M_AXI_ID_WIDTH-1 : 0]                 M_AXI_ARID_CNN      ,   M_AXI_ARID_yolo_output_process      ;   
    wire   [C_M_AXI_ADDR_WIDTH-1 : 0]               M_AXI_ARADDR_CNN    ,   M_AXI_ARADDR_yolo_output_process    ; 
    wire   [7 : 0]                                  M_AXI_ARLEN_CNN     ,   M_AXI_ARLEN_yolo_output_process     ;
    wire   [2 : 0]                                  M_AXI_ARSIZE_CNN    ,   M_AXI_ARSIZE_yolo_output_process    ; 
    wire   [1 : 0]                                  M_AXI_ARBURST_CNN   ,   M_AXI_ARBURST_yolo_output_process   ;
    wire                                            M_AXI_ARLOCK_CNN    ,   M_AXI_ARLOCK_yolo_output_process    ; 
    wire   [3 : 0]                                  M_AXI_ARCACHE_CNN   ,   M_AXI_ARCACHE_yolo_output_process   ;
    wire   [2 : 0]                                  M_AXI_ARPROT_CNN    ,   M_AXI_ARPROT_yolo_output_process    ;
    wire   [3 : 0]                                  M_AXI_ARQOS_CNN     ,   M_AXI_ARQOS_yolo_output_process     ;  
    wire   [C_M_AXI_ARUSER_WIDTH-1 : 0]             M_AXI_ARUSER_CNN    ,   M_AXI_ARUSER_yolo_output_process    ;
    wire                                            M_AXI_ARVALID_CNN   ,   M_AXI_ARVALID_yolo_output_process   ;
    assign M_AXI_ARID       =   (s_axi_start_sel) ? M_AXI_ARID_CNN      :   M_AXI_ARID_yolo_output_process      ;   
    assign M_AXI_ARADDR     =   (s_axi_start_sel) ? M_AXI_ARADDR_CNN    :   M_AXI_ARADDR_yolo_output_process    ; 
    assign M_AXI_ARLEN      =   (s_axi_start_sel) ? M_AXI_ARLEN_CNN     :   M_AXI_ARLEN_yolo_output_process     ;
    assign M_AXI_ARSIZE     =   (s_axi_start_sel) ? M_AXI_ARSIZE_CNN    :   M_AXI_ARSIZE_yolo_output_process    ; 
    assign M_AXI_ARBURST    =   (s_axi_start_sel) ? M_AXI_ARBURST_CNN   :   M_AXI_ARBURST_yolo_output_process   ;
    assign M_AXI_ARLOCK     =   (s_axi_start_sel) ? M_AXI_ARLOCK_CNN    :   M_AXI_ARLOCK_yolo_output_process    ; 
    assign M_AXI_ARCACHE    =   (s_axi_start_sel) ? M_AXI_ARCACHE_CNN   :   M_AXI_ARCACHE_yolo_output_process   ;
    assign M_AXI_ARPROT     =   (s_axi_start_sel) ? M_AXI_ARPROT_CNN    :   M_AXI_ARPROT_yolo_output_process    ;
    assign M_AXI_ARQOS      =   (s_axi_start_sel) ? M_AXI_ARQOS_CNN     :   M_AXI_ARQOS_yolo_output_process     ;  
    assign M_AXI_ARUSER     =   (s_axi_start_sel) ? M_AXI_ARUSER_CNN    :   M_AXI_ARUSER_yolo_output_process    ;
    assign M_AXI_ARVALID    =   (s_axi_start_sel) ? M_AXI_ARVALID_CNN   :   M_AXI_ARVALID_yolo_output_process   ;

    //----------------------------------------------------------------------------------
    //  (R) Channel control two axi
    //----------------------------------------------------------------------------------
    wire                                            M_AXI_RREADY_CNN    ,   M_AXI_RREADY_yolo_output_process    ;
    assign M_AXI_RREADY     =   (s_axi_start_sel) ? M_AXI_RREADY_CNN    :   M_AXI_RREADY_yolo_output_process    ;

    //----------------------------------------------------------------------------------
    //  IRQ and START
    //----------------------------------------------------------------------------------
    wire                                            IRQ_CNN             ,   IRQ_yolo_output_process             ;
    wire                                            s_axi_start_CNN     ,   s_axi_start_yolo_output_process     ;
    assign IRQ                  =   (s_axi_start_sel) ? IRQ_CNN             :   IRQ_yolo_output_process             ;
    assign s_axi_start_output   =   (s_axi_start_sel) ? s_axi_start_CNN     :   s_axi_start_yolo_output_process     ;
    assign s_axi_start_CNN                  = s_axi_start==0 ? 0 : s_axi_start_sel==0 && s_axi_start==1 ? 1 : s_axi_start_sel==1 && s_axi_start==1 ? 0 : 0;
    assign s_axi_start_yolo_output_process  = s_axi_start==0 ? 0 : s_axi_start_sel==0 && s_axi_start==1 ? 0 : s_axi_start_sel==1 && s_axi_start==1 ? 1 : 0;
    assign DEBUF_Layer_selc = layer_selc[5:0];
    assign DEBUG_Layer_type = cycle_data_selc[2:0];
    assign DEBUG_cycle_data = cycle_data;
 
// Instantiation of Axi Bus Interface S00_AXI
	CNN_Yolo_Outstanding_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) CNN_Yolo_Outstanding_v1_0_S00_AXI_inst (
	
	    .s_axi_start(s_axi_start),
	    .s_axi_start_sel(s_axi_start_sel),
        .s_axi_inst_0(s_axi_inst_0),
        .s_axi_inst_1(s_axi_inst_1),
        .s_axi_inst_2(s_axi_inst_2),
        .s_axi_inst_3(s_axi_inst_3),
        .s_axi_inst_4(s_axi_inst_4),
        .s_axi_Rerror_addr(s_axi_Rerror_addr),
        .s_axi_Werror_addr(s_axi_Werror_addr),
        .s_axi_Rerror(s_axi_Rerror),
        .s_axi_Werror(s_axi_Werror),
		.layer_selc(layer_selc),
		.cycle_data_selc(cycle_data_selc),
		.cycle_data(cycle_data),

		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	// Add user logic here
        CNN u_CNN (
        //S_AXI-Lite
        .S_AXI_ACLK             (s00_axi_aclk),
        .IRQ                    (IRQ_CNN),

        .s_axi_start(s_axi_start_CNN),
        .s_axi_inst_0(s_axi_inst_0),
        .s_axi_inst_1(s_axi_inst_1),
        .s_axi_inst_2(s_axi_inst_2),
        .s_axi_inst_3(s_axi_inst_3),
        .s_axi_inst_4(s_axi_inst_4),

        .s_axi_Rerror(s_axi_Rerror),
        .s_axi_Rerror_addr(s_axi_Rerror_addr),
        .s_axi_Werror(s_axi_Werror),
        .s_axi_Werror_addr(s_axi_Werror_addr),
        

        // M_AXI-Full
        .M_AXI_ACLK             (M_AXI_ACLK),
        .M_AXI_ARESETN          (M_AXI_ARESETN),
        //----------------------------------------------------------------------------------
        //  (AW) Channel
        //----------------------------------------------------------------------------------
        .M_AXI_AWREADY          (M_AXI_AWREADY),
        .M_AXI_AWID             (M_AXI_AWID_CNN),
        .M_AXI_AWADDR           (M_AXI_AWADDR_CNN),
        .M_AXI_AWLEN            (M_AXI_AWLEN_CNN),
        .M_AXI_AWSIZE           (M_AXI_AWSIZE_CNN),
        .M_AXI_AWBURST          (M_AXI_AWBURST_CNN),
        .M_AXI_AWLOCK           (M_AXI_AWLOCK_CNN),
        .M_AXI_AWCACHE          (M_AXI_AWCACHE_CNN),
        .M_AXI_AWPROT           (M_AXI_AWPROT_CNN),
        .M_AXI_AWQOS            (M_AXI_AWQOS_CNN),
        .M_AXI_AWUSER           (M_AXI_AWUSER_CNN),
        .M_AXI_AWVALID          (M_AXI_AWVALID_CNN),

        //----------------------------------------------------------------------------------
        //  (W) Channel
        //----------------------------------------------------------------------------------
        .M_AXI_WREADY           (M_AXI_WREADY),
        .M_AXI_WDATA            (M_AXI_WDATA_CNN),
        .M_AXI_WSTRB            (M_AXI_WSTRB_CNN),
        .M_AXI_WLAST            (M_AXI_WLAST_CNN),
        .M_AXI_WUSER            (M_AXI_WUSER_CNN),
        .M_AXI_WVALID           (M_AXI_WVALID_CNN),

        //----------------------------------------------------------------------------------
        //  (B) Channel
        //----------------------------------------------------------------------------------
        .M_AXI_BID              (M_AXI_BID),
        .M_AXI_BRESP            (M_AXI_BRESP),
        .M_AXI_BUSER            (M_AXI_BUSER),
        .M_AXI_BVALID           (M_AXI_BVALID),
        .M_AXI_BREADY           (M_AXI_BREADY_CNN),

        //----------------------------------------------------------------------------------
        //  (AR) Channel
        //----------------------------------------------------------------------------------
        .M_AXI_ARREADY          (M_AXI_ARREADY),
        .M_AXI_ARID             (M_AXI_ARID_CNN),
        .M_AXI_ARADDR           (M_AXI_ARADDR_CNN),
        .M_AXI_ARLEN            (M_AXI_ARLEN_CNN),
        .M_AXI_ARSIZE           (M_AXI_ARSIZE_CNN),
        .M_AXI_ARBURST          (M_AXI_ARBURST_CNN),
        .M_AXI_ARLOCK           (M_AXI_ARLOCK_CNN),
        .M_AXI_ARCACHE          (M_AXI_ARCACHE_CNN),
        .M_AXI_ARPROT           (M_AXI_ARPROT_CNN),
        .M_AXI_ARQOS            (M_AXI_ARQOS_CNN),
        .M_AXI_ARUSER           (M_AXI_ARUSER_CNN),
        .M_AXI_ARVALID          (M_AXI_ARVALID_CNN),

        //----------------------------------------------------------------------------------
        //  (R) Channel
        //----------------------------------------------------------------------------------
        .M_AXI_RID              (M_AXI_RID),
        .M_AXI_RDATA            (M_AXI_RDATA),
        .M_AXI_RRESP            (M_AXI_RRESP),
        .M_AXI_RLAST            (M_AXI_RLAST),
        .M_AXI_RUSER            (M_AXI_RUSER),
        .M_AXI_RVALID           (M_AXI_RVALID),
        .M_AXI_RREADY           (M_AXI_RREADY_CNN),
        

        .DEBUG_INPUT_state                  (DEBUG_INPUT_state),     
        .DEBUG_INPUT_start_valid_buffer     (DEBUG_INPUT_start_valid_buffer),                 
        .DEBUG_INPUT_state_input_ctrl       (DEBUG_INPUT_state_input_ctrl),                 
        .HARDWARE_VERSION                   (HARDWARE_VERSION),     
        .DEBUG_Master_Output_Finish         (DEBUG_Master_Output_Finish),             
        .DEBUG_Compute_Finish               (DEBUG_Compute_Finish),         
        .DEBUG_For_State_Finish             (DEBUG_For_State_Finish),         
        .DEBUG_Pad_Start_OBUF_FINISH        (DEBUG_Pad_Start_OBUF_FINISH),                 
        .DEBUG_CONV_FLAG                    (DEBUG_CONV_FLAG),     
        .DEBUG_IRQ_TO_MASTER_CTRL           (DEBUG_IRQ_TO_MASTER_CTRL),             
        .DEBUG_have_pool_ing                (DEBUG_have_pool_ing),         
        .DEBUG_ready_A                      (DEBUG_ready_A), 
        .DEBUG_ready_B                      (DEBUG_ready_B), 
        .DEBUG_start_A                      (DEBUG_start_A), 
        .DEBUG_start_B                      (DEBUG_start_B), 
        .DEBUG_obuf_state                   (DEBUG_obuf_state),     
        .DEBUG_obuf_pool_s                  (DEBUG_obuf_pool_s),     
        .DEBUG_obuf_finish_state            (DEBUG_obuf_finish_state),
        .DEBUG_obuf_rst                     (DEBUG_obuf_rst)
    );
	// User logic ends

    Cycle_counter u_Cycle_counter(
        .clk                                (M_AXI_ACLK), 
        .rst                                (!M_AXI_ARESETN), 
        .IRQ                                (IRQ), 
        .M_AXI_RVALID                       (M_AXI_RVALID), 
        .M_AXI_WVALID                       (M_AXI_WVALID), 
        .DEBUG_have_pool_ing                (DEBUG_have_pool_ing), 
        .DEBUG_INPUT_state_input_ctrl       (DEBUG_INPUT_state_input_ctrl), 
        .DEBUG_obuf_state                   (DEBUG_obuf_state), 
        .DEBUF_Layer_selc                   (layer_selc), 
        .DEBUG_Layer_type                   (cycle_data_selc), 
        .cycle_data                         (cycle_data)
    );

    //--------new add-------------
    YOLO_output_spilt_process u_YOLO_output_spilt_process (
        //S_AXI-Lite
        .S_AXI_ACLK             (s00_axi_aclk),
        .IRQ                    (IRQ_yolo_output_process),

        .s_axi_start(s_axi_start_yolo_output_process),
        .s_axi_inst_0(s_axi_inst_0),
        .s_axi_inst_1(s_axi_inst_1),
        .s_axi_inst_2(s_axi_inst_2),
        .s_axi_inst_3(s_axi_inst_3),
        .s_axi_inst_4(s_axi_inst_4),

        .s_axi_Rerror(s_axi_Rerror),
        .s_axi_Rerror_addr(s_axi_Rerror_addr),
        .s_axi_Werror(s_axi_Werror),
        .s_axi_Werror_addr(s_axi_Werror_addr),

        // M_AXI-Full
        .M_AXI_ACLK             (M_AXI_ACLK),
        .M_AXI_ARESETN          (M_AXI_ARESETN),
        //----------------------------------------------------------------------------------
        //  (AW) Channel
        //----------------------------------------------------------------------------------
        .M_AXI_AWREADY          (M_AXI_AWREADY),
        .M_AXI_AWID             (M_AXI_AWID_yolo_output_process),
        .M_AXI_AWADDR           (M_AXI_AWADDR_yolo_output_process),
        .M_AXI_AWLEN            (M_AXI_AWLEN_yolo_output_process),
        .M_AXI_AWSIZE           (M_AXI_AWSIZE_yolo_output_process),
        .M_AXI_AWBURST          (M_AXI_AWBURST_yolo_output_process),
        .M_AXI_AWLOCK           (M_AXI_AWLOCK_yolo_output_process),
        .M_AXI_AWCACHE          (M_AXI_AWCACHE_yolo_output_process),
        .M_AXI_AWPROT           (M_AXI_AWPROT_yolo_output_process),
        .M_AXI_AWQOS            (M_AXI_AWQOS_yolo_output_process),
        .M_AXI_AWUSER           (M_AXI_AWUSER_yolo_output_process),
        .M_AXI_AWVALID          (M_AXI_AWVALID_yolo_output_process),

        //----------------------------------------------------------------------------------
        //  (W) Channel
        //----------------------------------------------------------------------------------
        .M_AXI_WREADY           (M_AXI_WREADY),
        .M_AXI_WDATA            (M_AXI_WDATA_yolo_output_process),
        .M_AXI_WSTRB            (M_AXI_WSTRB_yolo_output_process),
        .M_AXI_WLAST            (M_AXI_WLAST_yolo_output_process),
        .M_AXI_WUSER            (M_AXI_WUSER_yolo_output_process),
        .M_AXI_WVALID           (M_AXI_WVALID_yolo_output_process),

        //----------------------------------------------------------------------------------
        //  (B) Channel
        //----------------------------------------------------------------------------------
        .M_AXI_BID              (M_AXI_BID),
        .M_AXI_BRESP            (M_AXI_BRESP),
        .M_AXI_BUSER            (M_AXI_BUSER),
        .M_AXI_BVALID           (M_AXI_BVALID),
        .M_AXI_BREADY           (M_AXI_BREADY_yolo_output_process),

        //----------------------------------------------------------------------------------
        //  (AR) Channel
        //----------------------------------------------------------------------------------
        .M_AXI_ARREADY          (M_AXI_ARREADY),
        .M_AXI_ARID             (M_AXI_ARID_yolo_output_process),
        .M_AXI_ARADDR           (M_AXI_ARADDR_yolo_output_process),
        .M_AXI_ARLEN            (M_AXI_ARLEN_yolo_output_process),
        .M_AXI_ARSIZE           (M_AXI_ARSIZE_yolo_output_process),
        .M_AXI_ARBURST          (M_AXI_ARBURST_yolo_output_process),
        .M_AXI_ARLOCK           (M_AXI_ARLOCK_yolo_output_process),
        .M_AXI_ARCACHE          (M_AXI_ARCACHE_yolo_output_process),
        .M_AXI_ARPROT           (M_AXI_ARPROT_yolo_output_process),
        .M_AXI_ARQOS            (M_AXI_ARQOS_yolo_output_process),
        .M_AXI_ARUSER           (M_AXI_ARUSER_yolo_output_process),
        .M_AXI_ARVALID          (M_AXI_ARVALID_yolo_output_process),

        //----------------------------------------------------------------------------------
        //  (R) Channel
        //----------------------------------------------------------------------------------
        .M_AXI_RID              (M_AXI_RID),
        .M_AXI_RDATA            (M_AXI_RDATA),
        .M_AXI_RRESP            (M_AXI_RRESP),
        .M_AXI_RLAST            (M_AXI_RLAST),
        .M_AXI_RUSER            (M_AXI_RUSER),
        .M_AXI_RVALID           (M_AXI_RVALID),
        .M_AXI_RREADY           (M_AXI_RREADY_yolo_output_process)
    );
	endmodule
