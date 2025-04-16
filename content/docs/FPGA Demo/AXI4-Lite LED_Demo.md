---
title: "AXI4-Lite LED Demo"
description: ""
icon: "code"
date: "2023-05-22T00:44:31+01:00"
lastmod: "2023-05-22T00:44:31+01:00"
draft: false
toc: true
weight: 210
---

{{% alert context="warning" text="The front matter `description` value for this page has been intentionally left empty in order to demonstrate FlexSearch's suggested results fallback behaviour." /%}}

## 1. 데모 설명  
AXI4-LITE 프로토콜을 활용하여 FPGA의 PS-PL간 인터페이스 연결을 수행하여 PS에서 PL영역의 LED를 켜거나 끄는 명령을 내리고, PS에서 PL영역의 LED의 현재 상태를 읽어오는 데모에 대해 기술한다.

보드는 Zybo-Z7-10 보드를 활용하지만 다른 보드에도 응용 가능하다.

해당 데모를 수행하기 위해 FPGA에 Petalinux가 빌드되어 있어야 한다. ([Petalinux 빌드 참고 링크)](/docs/FPGA-Demo/Petalinux-Build-Demo)

Petalinux가 없다면 Vitis를 활용해 해당 데모를 재현할 수 있다.



## 2. Background

FPGA로 제품을 구현할 때, [PS](/docs/terms/PS_region)에서 [PL](/docs/terms/PL_region) 회로를 제어할 일은 너무나 많다. 

PS-PL간 LED 제어/상태 데이터 전송을 위해서, AXI4-LITE 프로토콜을 활용한다. (AXI4 프로토콜 참고 링크 추가 예정)

PS에서 PL의 LED를 제어하는 명령은 "LED를 켜는 명령을 내리는 순간" 또는 "LED를 끄는 명령을 내리는 순간" 딱 1회만 일어난다. LED의 상태를 읽어오는 것 역시 그 순간 LED의 상태를 한 번 읽어오면 그만이다.

제어/상태 데이터의 특징은 연속적이지 않은 일회성 데이터라는 점이다. AXI4-LITE 프로토콜은 이러한 일회성 데이터의 전송에 널리 쓰인다.



## 3.DEMO
LED Demo를 구성하기 위한 Demo다. 3.1항목부터 차례대로 따라서 진행해보자.

1. <= 왼쪽 이모티콘으로 인덱스된 과정을 놓치지 말고 따라해보자.

### 3.1 Demo 구조
해당 데모의 구조는 아래 블록 다이어그램과 같다.

![Internal link preview tooltip](/images/content/led_demo_structure.png)  

각 블록의 기능은 아래와 같다.
- PS(Master) : FPGA의 PS 영역
- AXI Interconnect : PS와 PL간 AXI-LITE 프로토콜을 구성하는 버스
- lib_axi2local.v : AXI4-LITE 프로토콜이 구현되어 있는 Verilog 모듈
- lib_regmap.v : LED 제어/상태 데이터에 대한 레지스터 맵이 정의되어 있고, 레지스터에 LED 제어/상태 데이터를 저장하는 Verilog 모듈
- led_ctrl.v : 레지스터에 저장된 데이터에 따라 LED를 제어하는 Verilog 모듈

&nbsp;

### 3.2 Verilog 코드 설명
###   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;3.2.1 lib_regmap.v
```verilog
module lib_regmap
#(
    parameter AXI_AW = 12,
    parameter AXI_DW = 32
)
(
    input               S_AXI_ACLK,
    input               S_AXI_ARESETN,

    // write address(AW)
    input [AXI_AW-1:0]  S_AXI_AWADDR,
    input               S_AXI_AWVALID,
    output              S_AXI_AWREADY,

    // write data(W)
    input [AXI_DW-1:0]  S_AXI_WDATA,
    input               S_AXI_WVALID,
    output              S_AXI_WREADY,

    // write response(B)
    input               S_AXI_BREADY,
    output [1:0]        S_AXI_BRESP,
    output              S_AXI_BVALID,

    // Read Address(AR)
    input [AXI_AW-1:0]  S_AXI_ARADDR,
    input               S_AXI_ARVALID,
    output              S_AXI_ARREADY,

    // Read Data(R)
    input               S_AXI_RREADY,
    output [AXI_DW-1:0] S_AXI_RDATA,
    output [1:0]        S_AXI_RRESP,
    output              S_AXI_RVALID,

    // My Module
    input in1,          //PL -> PS (LED1 ON/OFF 상태)
    input in2,          //PL -> PS (LED2 ON/OFF 상태)
    input in3,          //PL -> PS (LED3 ON/OFF 상태)
    input in4,          //PL -> PS (LED4 ON/OFF 상태)
    output reg out1,    //PS -> PL (RST)
    output reg out2,    //PS -> PL (LED1 ON/OFF 명령)
    output reg out3,    //PS -> PL (LED2 ON/OFF 명령)
    output reg out4,    //PS -> PL (LED3 ON/OFF 명령)
    output reg out5     //PS -> PL (LED4 ON/OFF 명령)
);

wire clk = S_AXI_ACLK;
wire rst_n = S_AXI_ARESETN;

// Address Map //
// base_address + (offset), offset is localparam value
localparam LED_RST  = 12'h000;
localparam LED_ON_1_IN   = 12'h004;
localparam LED_ON_2_IN   = 12'h008;
localparam LED_ON_3_IN   = 12'h00c;
localparam LED_ON_4_IN   = 12'h010;

localparam LED_ON_1_OUT = 12'h014;
localparam LED_ON_2_OUT = 12'h018;
localparam LED_ON_3_OUT = 12'h01c;
localparam LED_ON_4_OUT = 12'h020;

reg signed [AXI_DW-1:0] pl_to_ps_data;
wire       [AXI_AW-1:0] pl_to_ps_addr;
wire                    pl_to_ps_ren;
wire       [AXI_DW-1:0] ps_to_pl_data;
wire       [AXI_AW-1:0] ps_to_pl_addr;
wire                    ps_to_pl_wen;

lib_axi2local
#(
    .AXI_AW(12),
    .AXI_DW(32)
)
u_lib_axi2local
(
    .S_AXI_ACLK     (S_AXI_ACLK),
    .S_AXI_ARESETN  (S_AXI_ARESETN),
    .S_AXI_AWADDR   (S_AXI_AWADDR),
    .S_AXI_AWVALID  (S_AXI_AWVALID),
    .S_AXI_AWREADY  (S_AXI_AWREADY),
    .S_AXI_WDATA    (S_AXI_WDATA),
    .S_AXI_WVALID   (S_AXI_WVALID),
    .S_AXI_WREADY   (S_AXI_WREADY),
    .S_AXI_BREADY   (S_AXI_BREADY),
    .S_AXI_BRESP    (S_AXI_BRESP),
    .S_AXI_BVALID   (S_AXI_BVALID),
    .S_AXI_ARADDR   (S_AXI_ARADDR),
    .S_AXI_ARVALID  (S_AXI_ARVALID),
    .S_AXI_ARREADY  (S_AXI_ARREADY),
    .S_AXI_RREADY   (S_AXI_RREADY),
    .S_AXI_RDATA    (S_AXI_RDATA),
    .S_AXI_RRESP    (S_AXI_RRESP),
    .S_AXI_RVALID   (S_AXI_RVALID),

    .pl_to_ps_data  (pl_to_ps_data),
    .pl_to_ps_addr  (pl_to_ps_addr),
    .pl_to_ps_ren   (pl_to_ps_ren),
    .ps_to_pl_data  (ps_to_pl_data),
    .ps_to_pl_addr  (ps_to_pl_addr),
    .ps_to_pl_wen   (ps_to_pl_wen)
);

// PS write to PL
/////////////////
always @(posedge clk ) begin
    if(!rst_n) begin
        out1 <= 0;
        out2 <= 0;
        out3 <= 0;
        out4 <= 0;
        out5 <= 0;
    end
    else if(ps_to_pl_wen) begin
        case(ps_to_pl_addr)
            LED_RST     : out1 <= ps_to_pl_data[0];
            LED_ON_1_IN : out2 <= ps_to_pl_data[0];
            LED_ON_2_IN : out3 <= ps_to_pl_data[0];
            LED_ON_3_IN : out4 <= ps_to_pl_data[0];
            LED_ON_4_IN : out5 <= ps_to_pl_data[0];
            default: ;
        endcase
    end
end

// PS read from PL
//////////////////
always @(posedge clk ) begin
    if(!rst_n) begin
        pl_to_ps_data <= 0;
    end
    else if(pl_to_ps_ren) begin
        case(pl_to_ps_addr)
            LED_ON_1_OUT : pl_to_ps_data <= {31'b0,in1};
            LED_ON_2_OUT : pl_to_ps_data <= {31'b0,in2};
            LED_ON_3_OUT : pl_to_ps_data <= {31'b0,in3};
            LED_ON_4_OUT : pl_to_ps_data <= {31'b0,in4};
            default: ;
        endcase
    end
end


endmodule
```

lib_regmap.v 코드를 살펴보자.

- 7~34 Line : AXI4-LITE 프로토콜 인터페이스 포트. PS와 PL의 레지스터 맵(lib_regmap.v) 사이에서 LED 제어/상태 데이터를 주고 받는 인터페이스 포트

- 37~45 Line : PL의 레지스터 맵(lib_regmap.v)와 PL의 LED 컨트롤러(led_ctrl.v) 사이에서 데이터를 주고 받는 포트이다.

- 53~62 Line : 3.3 항목의 Address Editor 에서 설정된 Master Base Address를 바탕으로 4byte offset을 줘 LED 제어/상태 데이터를 저장하는 레지스터 맵 구현 부분. 예를 들어 Master Base Address가 0x4000_0000이면 LED3을 켜는 명령은 0x4000_000C에 입력된다. 이 데이터가 1이면 led_ctrl.v는 LED3을 켠다.

- 107~125 Line : PS영역이 LED 제어 명령을 PL의 레지스터에 저장하는 부분이다. ps_to_pl_wen신호는 lib_axi2local 모듈에서 AXI4-LITE 프로토콜에 의해 1이 된다. ps_to_pl_data 신호는 PS에서 LED를 제어하는 명령을 전달한다. PS는 S_AXI_WDATA를 통해 LED 제어 명령을 보내면, lib_axi2local 모듈에서 AXI4-LITE 프로토콜을 통해 S_AXI_WDATA를 ps_to_pl_data로 전달한다.

- 129~142 Line : PL영역이 현재 LED 상태를 PL의 레지스터에 저장하는 부분이다. in1 부터 in4 까지의 신호가 각각의 LED 상태이다. lib_axi2local에서 AXI4-LITE 프로토콜을 통해 pl_to_ps_ren이 1이 되면 레지스터에 있는 데이터가 pl_to_ps_data로 이동한다. 그리고 lib_axi2local 모듈로 들어가 AXI4-LITE 프로토콜에 의해 S_AXI_RDATA로 LED 상태 정보가 PS로 전달된다.

&nbsp;
###   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;3.2.2 led_ctrl.v
```verilog
module led_ctrl(
    input clk,
    input rst,
    input sw_rst,
    input din_led_1_on,
    input din_led_2_on,
    input din_led_3_on,
    input din_led_4_on,

    output reg dout_led_1_on,
    output reg dout_led_2_on,
    output reg dout_led_3_on,
    output reg dout_led_4_on
);


always @(posedge clk ) begin
    if(sw_rst) begin
        dout_led_1_on <= 0;
    end
    else if(din_led_1_on) begin
        dout_led_1_on <= 1;
    end
    else begin
        dout_led_1_on <= 0;
    end
end

always @(posedge clk ) begin
    if(sw_rst) begin
        dout_led_2_on <= 0;
    end
    else if(din_led_2_on) begin
        dout_led_2_on <= 1;
    end
    else begin
        dout_led_2_on <= 0;
    end
end

always @(posedge clk ) begin
    if(sw_rst) begin
        dout_led_3_on <= 0;
    end
    else if(din_led_3_on) begin
        dout_led_3_on <= 1;
    end
    else begin
        dout_led_3_on <= 0;
    end
end

always @(posedge clk ) begin
    if(sw_rst) begin
        dout_led_4_on <= 0;
    end
    else if(din_led_4_on) begin
        dout_led_4_on <= 1;
    end
    else begin
        dout_led_4_on <= 0;
    end
end

ila_0 u_ila_0 (
	.clk(clk), // input wire clk
	.probe0(sw_rst), // input wire [0:0]  probe0  
	.probe1(din_led_1_on), // input wire [0:0]  probe1 
	.probe2(din_led_2_on), // input wire [0:0]  probe2 
	.probe3(din_led_3_on), // input wire [0:0]  probe3 
	.probe4(din_led_4_on), // input wire [0:0]  probe4 
	.probe5(dout_led_1_on), // input wire [0:0]  probe5 
	.probe6(dout_led_2_on), // input wire [0:0]  probe6 
	.probe7(dout_led_3_on), // input wire [0:0]  probe7 
	.probe8(dout_led_4_on) // input wire [0:0]  probe8
);

endmodule

```

led_ctrl.v에서 코드를 살펴보자.
- 5~8 Line: LED 제어 신호가 들어오는 포트. lib_regmap.v의 out 신호와 연결된다.
- 10~13 Line : LED 상태 신호를 내보내는 포트. lib_regmap.v의 in 신호와 연결된다.
- 17~27 Line : din_led_1_on 신호가 1이면 PS에서 LED1을 켜라는 의미다. 따라서 LED 상태 신호를 1로 바꿔준다.
- 나머지 : LED2, LED3, LED4에서 17~27 Line과 같은 동작을 수행한다.

&nbsp;
###   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;3.2.3 lib_axi2local.v
```verilog
module lib_axi2local
#(
    parameter AXI_AW = 12,
    parameter AXI_DW = 32
)
(
    //-------- AXI Interface ----------//
    input               S_AXI_ACLK,       //AXI Clock
    input               S_AXI_ARESETN,    //AXI Negative Reset

    // Write Address     (PS write address to PL)
    input [AXI_AW-1:0]  S_AXI_AWADDR,
    input               S_AXI_AWVALID,
    output              S_AXI_AWREADY,

    // Write Data        (PS write data to PL)
    input [AXI_DW-1:0]  S_AXI_WDATA,
    input               S_AXI_WVALID,
    output              S_AXI_WREADY,

    // Write Response   
    input               S_AXI_BREADY,
    output [1:0]        S_AXI_BRESP,
    output              S_AXI_BVALID,

    // Read Address      (PS Read address from PL)
    input [AXI_AW-1:0]  S_AXI_ARADDR,
    input               S_AXI_ARVALID,
    output              S_AXI_ARREADY,

    // Read Data         (PS Read data from PL)
    input               S_AXI_RREADY,
    output [AXI_DW-1:0] S_AXI_RDATA,
    output [1:0]        S_AXI_RRESP,
    output              S_AXI_RVALID,
    //---------------------------------//

    //--------- Local Interface -------//
    input   [AXI_DW-1:0] pl_to_ps_data, // --> S_AXI_RDATA
    output  [AXI_AW-1:0] pl_to_ps_addr, // <-- S_AXI_ARADDR
    output               pl_to_ps_ren,   // read enable

    output  [AXI_DW-1:0] ps_to_pl_data, // <-- S_AXI_WDATA
    output  [AXI_AW-1:0] ps_to_pl_addr, // <-- S_AXI_WADDR
    output               ps_to_pl_wen   // write enable
);

// AXI4-LITE wires
reg [AXI_AW-1 : 0] 	r_axi_awaddr;
reg  	            r_axi_awready;
reg  	            r_axi_wready;
reg [1 : 0] 	    r_axi_bresp;
reg  	            r_axi_bvalid   = 1'b0;
reg [AXI_AW-1 : 0] 	r_axi_araddr;
reg  	            r_axi_arready;
reg [AXI_DW-1 : 0] 	r_axi_rdata;
reg [1 : 0] 	    r_axi_rresp;
reg  	            r_axi_rvalid;

assign S_AXI_AWREADY  = r_axi_awready;
assign S_AXI_WREADY	  = r_axi_wready;
assign S_AXI_BRESP	  = r_axi_bresp;
assign S_AXI_BVALID	  = r_axi_bvalid;
assign S_AXI_ARREADY  = r_axi_arready;
assign S_AXI_RDATA	  = r_axi_rdata;
assign S_AXI_RRESP	  = r_axi_rresp;
assign S_AXI_RVALID	  = r_axi_rvalid;

reg r_aw_en;

// r_axi_awready //
always @(posedge S_AXI_ACLK ) begin
    if (!S_AXI_ARESETN) begin
        r_axi_awready <= 1'b0;
        r_aw_en       <= 1'b1;
    end
    else begin
        if (~r_axi_awready && S_AXI_AWVALID && S_AXI_WVALID && r_aw_en) begin
            r_axi_awready <= 1'b1;
            r_aw_en       <= 1'b0;
        end
        else if (S_AXI_BREADY && r_axi_bvalid) begin
            r_axi_awready <= 1'b0;
            r_aw_en       <= 1'b1;
        end
        else begin
            r_axi_awready <= 1'b0;
        end
    end
end

// r_axi_awaddr //
always @(posedge S_AXI_ACLK ) begin
    if (!S_AXI_ARESETN) begin
        r_axi_awaddr <= 0;
    end
    else begin
        if(~r_axi_awready && S_AXI_AWVALID && S_AXI_WVALID && r_aw_en) begin
            r_axi_awaddr <= S_AXI_AWADDR;
        end
    end
end

// r_axi_wready //
always @(posedge S_AXI_ACLK ) begin
    if (!S_AXI_ARESETN) begin
        r_axi_wready <= 1'b0;
    end
    else begin
        if (~r_axi_awready && S_AXI_AWVALID && S_AXI_WVALID && r_aw_en) begin
            r_axi_wready <= 1'b1;
        end
        else begin
            r_axi_wready <= 1'b0;
        end
    end
end


always @( posedge S_AXI_ACLK )begin
    if ( S_AXI_ARESETN == 1'b0 ) begin
        r_axi_bvalid  <= 0;
        r_axi_bresp   <= 2'b0;
    end 
    else begin    
        if (r_axi_awready && S_AXI_AWVALID && ~r_axi_bvalid && r_axi_wready && S_AXI_WVALID) begin
            r_axi_bvalid <= 1'b1;
            r_axi_bresp  <= 2'b0; // 'OKAY' response 
        end
        else begin
            if (S_AXI_BREADY && r_axi_bvalid) begin
                r_axi_bvalid <= 1'b0; 
            end  
        end
    end
end   

// PL Write //
assign ps_to_pl_addr = r_axi_awaddr;
assign ps_to_pl_data = S_AXI_WDATA;
assign ps_to_pl_wen = r_axi_wready && S_AXI_WVALID && r_axi_awready && S_AXI_AWVALID;

assign S_AXI_AWREADY = r_axi_awready;
assign S_AXI_WREADY  = r_axi_wready;
assign S_AXI_BRESP   = r_axi_bresp;
assign S_AXI_BVALID  = r_axi_bvalid;


// Read address && response //
always @( posedge S_AXI_ACLK ) begin
	if ( S_AXI_ARESETN == 1'b0 ) begin
		r_axi_arready <= 1'b0;
		r_axi_araddr  <= 32'b0;
	end
	else begin
		if (~r_axi_arready && S_AXI_ARVALID) begin
			r_axi_arready <= 1'b1;
			r_axi_araddr  <= S_AXI_ARADDR;
		end
		else begin
			r_axi_arready <= 1'b0;
		end
	end
end

always @( posedge S_AXI_ACLK ) begin
	if ( S_AXI_ARESETN == 1'b0 ) begin
		r_axi_rvalid <= 0;
		r_axi_rresp  <= 0;
	end
	else begin
		if (r_axi_arready && S_AXI_ARVALID && ~r_axi_rvalid) begin
			r_axi_rvalid <= 1'b1;
			r_axi_rresp  <= 2'b0;
		end
		else if (r_axi_rvalid && S_AXI_RREADY) begin
			r_axi_rvalid <= 1'b0;
		end
	end
end

assign pl_to_ps_ren = r_axi_arready & S_AXI_ARVALID & ~r_axi_rvalid;
assign pl_to_ps_addr = r_axi_araddr;

assign S_AXI_ARREADY = r_axi_arready;
assign S_AXI_RDATA   = pl_to_ps_data;
assign S_AXI_RRESP   = r_axi_rresp;
assign S_AXI_RVALID  = r_axi_rvalid;


endmodule

```
lib_axi2local.v 코드를 살펴보자.

- 8~35 Line : AXI4-LITE 인터페이스 포트다. LED 제어/상태 데이터가 이동한다.

- 39~45 Line : PL로부터 LED의 상태 정보를 읽어 pl_to_ps_data로 들어오면 AXI4-LITE 프로토콜에 의해 pl_to_ps_data는 S_AXI_RDATA로 전달되어 PS로 이동한다.

- 71~146 Line : AXI4-LITE 프로토콜 구현 부분. 자세한 내용은 (AXI4-프로토콜 문서 참고)

&nbsp;
###   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;3.2.4 led_top.v
```verilog
module led_top
#(
    parameter AXI_AW = 12,
    parameter AXI_DW = 32
)
(
    // CLK , RST
    input               S_AXI_ACLK,
    input               S_AXI_ARESETN,

    // write address(AW)
    input [AXI_AW-1:0]  S_AXI_AWADDR,
    input               S_AXI_AWVALID,
    output              S_AXI_AWREADY,

    // write data(W)
    input [AXI_DW-1:0]  S_AXI_WDATA,
    input               S_AXI_WVALID,
    output              S_AXI_WREADY,

    // write response(B)
    input               S_AXI_BREADY,
    output [1:0]        S_AXI_BRESP,
    output              S_AXI_BVALID,

    // Read Address(AR)
    input [AXI_AW-1:0]  S_AXI_ARADDR,
    input               S_AXI_ARVALID,
    output              S_AXI_ARREADY,

    // Read Data(R)
    input               S_AXI_RREADY,
    output [AXI_DW-1:0] S_AXI_RDATA,
    output [1:0]        S_AXI_RRESP,
    output              S_AXI_RVALID,

    // LED CTRL
    output led_1_on_result,
    output led_2_on_result,
    output led_3_on_result,
    output led_4_on_result  
);

wire sw_rst;
wire led_1_on;
wire led_2_on;
wire led_3_on;
wire led_4_on;
lib_regmap
#(
    .AXI_AW(12),
    .AXI_DW(32)
)
u_led_regmap
(
    .S_AXI_ACLK     (S_AXI_ACLK),
    .S_AXI_ARESETN  (S_AXI_ARESETN),
    .S_AXI_AWADDR   (S_AXI_AWADDR),
    .S_AXI_AWVALID  (S_AXI_AWVALID),
    .S_AXI_AWREADY  (S_AXI_AWREADY),
    .S_AXI_WDATA    (S_AXI_WDATA),
    .S_AXI_WVALID   (S_AXI_WVALID),
    .S_AXI_WREADY   (S_AXI_WREADY),
    .S_AXI_BREADY   (S_AXI_BREADY),
    .S_AXI_BRESP    (S_AXI_BRESP),
    .S_AXI_BVALID   (S_AXI_BVALID),
    .S_AXI_ARADDR   (S_AXI_ARADDR),
    .S_AXI_ARVALID  (S_AXI_ARVALID),
    .S_AXI_ARREADY  (S_AXI_ARREADY),
    .S_AXI_RREADY   (S_AXI_RREADY),
    .S_AXI_RDATA    (S_AXI_RDATA),
    .S_AXI_RRESP    (S_AXI_RRESP),
    .S_AXI_RVALID   (S_AXI_RVALID),

    .in1            (led_1_on_result),  //PL -> PS
    .in2            (led_2_on_result),  //PL -> PS
    .in3            (led_3_on_result),  //PL -> PS
    .in4            (led_4_on_result),  //PL -> PS

    .out1           (sw_rst),    //PS -> PL
    .out2           (led_1_on),   //PS -> PL
    .out3           (led_2_on),  //PS -> PL
    .out4           (led_3_on),   //PS -> PL
    .out5           (led_4_on)   //PS -> PL
);


led_ctrl u_led_ctrl
(
    .clk            (S_AXI_ACLK),
    .rst            (!S_AXI_ARESETN),
    .sw_rst         (sw_rst),
    .din_led_1_on   (led_1_on),
    .din_led_2_on   (led_2_on),
    .din_led_3_on   (led_3_on),
    .din_led_4_on   (led_4_on),

    .dout_led_1_on  (led_1_on_result),
    .dout_led_2_on  (led_2_on_result),
    .dout_led_3_on  (led_3_on_result),
    .dout_led_4_on  (led_4_on_result)
);

endmodule
```

led_top.v 코드를 살펴보자.

사실 특별한건 없다. 하위 모듈을 라우팅하는 부분이다.

&nbsp;
###   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;3.2.5 Zybo-Z7-Master.xdc
```verilog
## This file is a general .xdc for the Zybo Z7 Rev. B
## It is compatible with the Zybo Z7-20 and Zybo Z7-10
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

##Clock signal
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { sysclk }]; #IO_L12P_T1_MRCC_35 Sch=sysclk
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { sysclk }];


##Switches
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }]; #IO_L19N_T3_VREF_35 Sch=sw[0]
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }]; #IO_L24P_T3_34 Sch=sw[1]
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }]; #IO_L4N_T0_34 Sch=sw[2]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }]; #IO_L9P_T1_DQS_34 Sch=sw[3]


##Buttons
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { btn[0] }]; #IO_L12N_T1_MRCC_35 Sch=btn[0]
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { btn[1] }]; #IO_L24N_T3_34 Sch=btn[1]
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { btn[2] }]; #IO_L10P_T1_AD11P_35 Sch=btn[2]
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { btn[3] }]; #IO_L7P_T1_34 Sch=btn[3]


##LEDs
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led_1_on_result_0 }]; #IO_L23P_T3_35 Sch=led[0]
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led_2_on_result_0 }]; #IO_L23N_T3_35 Sch=led[1]
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led_3_on_result_0 }]; #IO_0_35 Sch=led[2]
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led_4_on_result_0 }]; #IO_L3N_T0_DQS_AD1N_35 Sch=led[3]


##RGB LED 5 (Zybo Z7-20 only)
#set_property -dict { PACKAGE_PIN Y11   IOSTANDARD LVCMOS33 } [get_ports { led5_r }]; #IO_L18N_T2_13 Sch=led5_r
#set_property -dict { PACKAGE_PIN T5    IOSTANDARD LVCMOS33 } [get_ports { led5_g }]; #IO_L19P_T3_13 Sch=led5_g
#set_property -dict { PACKAGE_PIN Y12   IOSTANDARD LVCMOS33 } [get_ports { led5_b }]; #IO_L20P_T3_13 Sch=led5_b

##RGB LED 6
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { led6_r }]; #IO_L18P_T2_34 Sch=led6_r
set_property -dict { PACKAGE_PIN F17   IOSTANDARD LVCMOS33 } [get_ports { led6_g }]; #IO_L6N_T0_VREF_35 Sch=led6_g
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports { led6_b }]; #IO_L8P_T1_AD10P_35 Sch=led6_b

```
xdc 파일은 PL에서 LED 상태 정보 신호를 읽어 실제 FPGA LED HW 회로에 연결하도록 정의하는 파일이다.

27-30 Line이 의미하는 바는 led_(1,2,3,4)_on_result_0 포트를 각각 FPGA핀 M14, M15, G14, D18에 연결하겠다는 의미다.

M14, M15, G14, D18핀이 곧 LED1~LED4를 제어하는 핀이다. PS로 부터 LED를 켜라는 명령을 받으면 PL의 led_ctrl.v에서 LED를 켜기 위해 1을 내보낸다. 그러면 LVCMOS33에 해당하는 전압이 방출되어 M14, M15, G14, D18핀에 공급된다. 그리고 LED가 실제로 켜진다.

M14, M15, G14, D18핀이 LED핀과 연결되는지 알 수 있는 방법은 회로도를 보는 것이다.

https://digilent.com/reference/_media/reference/programmable-logic/zybo/zybo_sch.pdf?srsltid=AfmBOopNZVIkscMnF8CmGXuTW2xjPljicWR5rEVrtv6ky_yxk8rx1tCQ

위 링크에 접속하면 Zybo-Z7-10의 회로도를 볼 수 있다. M14, M15, G14, D18핀을 검색해보면 LED와 연결되어 있음을 확인할 수 있다. 

### 3.3 Vivado 프로젝트 구성
이제 Vivado 프로젝트를 구성할 차례다.

1. Zybo-z7-10 파트로 Vivado 프로젝트를 생성한다. (만약 다른 보드라면 해당 파츠에 맞게 생성)

2. lib_regmap.v, led_ctrl.v, lib_axi2local.v, led_top.v 4개의 코드를 Design Sources에 추가한다.

3. Zybo-z7-Master.xdc를 Constraints에 추가한다. (만약 다른 보드라면 회로도를 보고 LED핀을 찾아서 수정해야 한다.)

4. Create Block Design 클릭 -> 빈 공간에 마우스 오른쪽 클릭 -> "Add Module" 클릭 -> led_top.v를 선택해 추가한다.

5. 아래 그림과 같이 Block Design을 구성한다. led_top_v1_0을 제외한 모든 IP는 ctrl+I를 누른 뒤 검색으로 추가 가능하다.

    ![Internal link preview tooltip](/images/content/led_demo_block_design.png)

    Block Design을 구성하는 IP에 대해 간단히 설명한다.

    - ZYNQ7 Processing System : Zynq-Z7-10보드에 탑재되어 있는 PS영역 IP다. (다른 보드를 쓴다면 보드에 맞는 PS IP를 사용하자)
    - Processor System Reset : PS영역 및 PL영역에 Reset을 인가하는 IP다.
    - AXI Interconnect : PS와 PL영역을 AXI4-LITE 프로토콜로 연결해주는 IP다.
    - AXI Protocol Checker : PS-PL간 데이터 전송이 이루어 질 때 AXI4-LITE 프로토콜을 만족하는 검사하는 IP다.
    - led_top_v1_0 : PS영역으로 부터 명령을 받아 LED를 켜거나 끄고, 현재 LED 상태를 전송하는 PL 로직이다.
    - ILA : AXI Protocol Checker에서 프로토콜을 검사한 결과를 보기 위한 IP다.
&nbsp;  
&nbsp;

    PS, PL 인터페이스를 구성할 때, 위 Block Design과 같은 구성은 가장 기본이 되고 가장 많이 쓰이는 형태니 꼭 기억하자.

6. Diagram 옆에 있는 Address Editor를 클릭하고 Master Base Address를 확인한다.

    ![Internal link preview tooltip](/images/content/led_demo_address.png)

    Master Base Address는 레지스터 맵의 시작 주소를 의미한다. 만약 0x4000_0000에 PS영역이 PL의 LED 상태를 초기화 하는 리셋 명령 데이터를 준다고 가정하자(데이터가 1일 때 리셋).
    
     그러면 PL은 0x4000_0000 주소에서 데이터를 읽을 때 만약 그 데이터가 1이라면 LED 리셋을 수행한다.

    만약 0x4000_0004에 PS영역이 LED1을 켜는 명령을 준다고 가정하자(데이터가 1일 때 LED1 ON). 그러면 PL은 0x4000_0000 주소에서 데이터를 읽을 때 그 데이터가 1이라면 LED1을 켠다.

    그리고 위의 PS,PL이 레지스터 맵에 데이터를 쓰거나 읽는 모든 과정은 AXI4-LITE 프로토콜을 기반으로 동작한다.

7. F6을 눌러 Validate Design을 수행한다
8. Design Source의 design_1.bd파일을 마우스 오른쪽 클릭 -> Create HDL Wrapper 클릭

    ![Internal link preview tooltip](/images/content/led_demo_HDL_wrapper.png)

9. design_1_wrapper.v가 생성되었는지 확인한다.

    ![Internal link preview tooltip](/images/content/led_demo_HDL_wrapper_check.png)

10. design_1_wrapper.v 오른쪽 마우스 클릭 -> set as Top 선택 (버튼이 비활성화 되어 있으면 안해도 됨)

11. Generate Bitstream 오른쪽 마우스 클릭 -> Bitstream Settings 클릭 -> -bin_file* 체크하기

    ![Internal link preview tooltip](/images/content/led_demo_bitstream_set.png)

12. Generate Bitstream 클릭


&nbsp;

### 3.4 Petalinux 빌드
3.3 11번에서 생성된 .bin파일을 Petalinux에 옮길 차례다. 보통 bin파일 생성 경로는 아래와 같다.

    ex) <프로젝트 이름>.runs/impl_1/design_1_wrapper.bin   
    
&nbsp;

※ 만약 3.3항목의 4번에서 Create Block Design을 할 때 이름을 수정했다면 design_1_wrapper.bin이 다른 이름으로 생성되었을 것이다.

1. Petalinux가 포팅된 Zybo-Z7-10 보드 전원을 SD카드 모드로 부팅하고 FPGA보드와 컴퓨터를 이더넷으로 연결한다.

2. Petalinux가 부팅되면 login을 root로 한다. 비밀번호도 root

    ![Internal link preview tooltip](/images/content/led_demo_peta_boot.png)

3. 윈도우에서 새롭게 터미널을 하나 연다.

4. 새롭게 연 터미널에서 "scp -O design_wrapper.bin root@<ip 주소>:<bin파일 저장 경로>" 명령어를 입력한다.
    ```
        ex) scp -O design_wrapper.bin root@192.168.255.10:/home/root
    ```
5. 비밀번호는 root

6. 아래 그림과 같이 비트 파일이 이동하면 성공

    ![Internal link preview tooltip](/images/content/led_demo_bitstream_scp.png)

7. fpgautil -b design_wrapper.bin 명령어 입력 
    ```
        fpgautil -b design_wrapper.bin
    ```
    &nbsp;

8. 아래 그림과 같이 비트파일이 정상적으로 올라가면 성공이다.

    ![Internal link preview tooltip](/images/content/led_demo_fpgautil.png)

    &nbsp;

9. Petalinux에서 "devmem 0x40000004 32 1" 명령어를 입력한다.
    ```
    devmem 0x40000004 32 1
    ```
    &nbsp;

    ![Internal link preview tooltip](/images/content/led_demo_led.png)

    &nbsp;

    위 명령어는 PS에서 레지스터 맵 0x4000_0004주소에 데이터 1을 쓴다는 의미이다. lib_regmap.v에서 0x4000_0004는 LED1을 켜는 제어 신호이다. FPGA 보드의 LED1이 켜짐을 확인할 수 있다.

10. Petalinux에서 "devmem 0x40000014" 명령어를 입력한다.
    ```
    devmem 0x40000014"
    ```
    &nbsp;

    ![Internal link preview tooltip](/images/content/led_demo_bitstream_led1_read.png)

    위 명령어는 PS가 레지스터 맵 0x4000_0014주소에서 데이터를 읽어 오겠다는 의미이다. lib_regmap.v에서 0x4000_0014에 LED1의 현재 상태을 저장한다. 데이터 1이 읽히면 정상적으로 LED1이 켜져있다는 신호다.

11. Petalinux에서 "devmem 0x40000008 32 1" 명령어를 입력한다.
    ```
    devmem 0x40000008 32 1
    ```
    &nbsp;

    ![Internal link preview tooltip](/images/content/led_demo_led2.png)

    LED2가 켜짐을 확인할 수 있다.
    
12. Petalinux에서 "devmem 0x40000018" 명령어를 입력한다.    
    ```
    devmem 0x40000018"
    ```
    &nbsp;

    ![Internal link preview tooltip](/images/content/led_demo_bitstream_led2_read.png)

13. 같은 방식으로 led3, led4도 PS에서 제어하여 켜거나 끌 수 있다. 그리고 LED 상태 역시 동일하게 읽을 수 있다.