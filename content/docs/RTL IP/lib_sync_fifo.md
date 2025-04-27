---
title: "lib_axis_fifo_sync.v"
description: ""
icon: "code"
date: "2023-05-22T00:44:31+01:00"
lastmod: "2023-05-22T00:44:31+01:00"
draft: false
toc: true
weight: 210
---

{{% alert context="warning" text="The front matter `description` value for this page has been intentionally left empty in order to demonstrate FlexSearch's suggested results fallback behaviour." /%}}

## 모듈 설명  
Synchronous FIFO에 대한 개념을 설명하고 AXI4-Stream 인터페이스에 맞게 RTL로 구현하는 과정을 기술한다.

## 1. Synchronous FIFO 란?
FIFO(First-In-First-Out)의 줄임말이다. 말 그대로 먼저 들어온 데이터가 먼저 나간다는 뜻이다.

FIFO는 기본적으로 읽기 포인터와 쓰기 포인터로 동작한다. 아래 예제를 통해 FIFO의 동작원리를 알아보자.

## 2. Synchronous FIFO 예제

DEPTH가 8인 FIFO를 예제로 설명을 진행한다. DEPTH란 FIFO에 저장될 수 있는 데이터 개수를 의미한다. 

Verilog 특성상 FIFO는 데이터를 저장하는 F/F로 구현된다. F/F은 다음 클럭에서 값이 업데이트 된다는 것을 주목하면서 아래 예제를 따라가자.

&nbsp;

![Internal link preview tooltip](/images/content/sync_fifo/ex1.png)  

- 현재 wr_ptr의 index가 0이므로 FIFO의 0번 index에 x[0] 데이터가 저장되는 중이다.

- fifo index 0번에 데이터가 저장되고 있으므로 다음 클럭에 wr_ptr의 index를 1 증가 시켜 다음 데이터를 받을 준비를 한다.

![Internal link preview tooltip](/images/content/sync_fifo/ex2.png) 

- CLK1에서 CLK2가 되면서 FIFO index 0에 x[0] 데이터가 최종 저장된다.

- CLK1에서 CLK2가 되면서 wr_ptr이 0에서 1로 최종 증가되었다.

- 동시에 현재 wr_ptr의 index가 1이므로 FIFO의 1번 index에 x[1] 데이터를 저장하는 중이다.

- FIFO index 1번에 데이터가 저장되고 있으므로 다음 클럭에 wr_ptr의 index를 1 증가시켜 다음 데이터를 받을 준비를 한다.

![Internal link preview tooltip](/images/content/sync_fifo/ex3.png)

- CLK2에서 CLK3이 되면서 FIFO index 1에 x[1] 데이터가 최종 저장된다.

- CLK2에서 CLK3이 되면서 wr_ptr의 index가 1에서 2로 최종 증가되었다.

- 동시에 현재 wr_ptr의 index가 2이므로 FIFO의 2번 index에 x[2] 데이터를 저장하는 중이다.

- FIFO index 2번에 데이터가 저장되고 있으므로 다음 클럭에 wr_ptr의 index를 1 증가시켜 다음 데이터를 받을 준비를 한다.

![Internal link preview tooltip](/images/content/sync_fifo/ex4.png)

- 데이터를 계속 저장하여 CLK6이 되었다. CLK5에서 CLK6이 되면서 FIFO의 6번 index에 x[6]이 FIFO에 최종 저장되었다.

- 동시에 현재 wr_ptr의 index가 7이므로 FIFO의 7번 index에 x[7] 데이터를 저장하는 중이다.

- FIFO index 7번에 데이터가 저장되고 있으므로 다음 클럭에 wr_ptr의 index를 1 증가시켜 다음 데이터를 받을 준비를 한다.

![Internal link preview tooltip](/images/content/sync_fifo/ex5.png)

- CLK6에서 CLK7이 되면서 FIFO index 7에 x[7] 데이터가 최종 저장된다.

- CLK6에서 CLK7이 되면서 wr_ptr이 최종 1 증가되었다.

- 현재 wr_ptr의 index는 8이다. 그리고 rd_ptr의 index는 0이다. 8(1000)과 0(0000)은 MSB가 다르고 MSB를 제외한 나머지 하위 비트가 같다. 이러한 경우 FIFO가 Full 상태임을 확인할 수 있다.

- FIFO가 Full 상태이므로 더 이상 데이터를 받을 수 없다.

![Internal link preview tooltip](/images/content/sync_fifo/ex6.png)

- 이제 데이터를 읽어보자.

- rd_ptr의 index는 0이다. 따라서 FIFO index 0에서 데이터를 읽는 중이다.

- FIFO index 0에서 데이터를 읽고 있으므로 다음 클럭에 rd_ptr index를 1 증가 시켜 다음 데이터를 읽을 준비를 한다.

![Internal link preview tooltip](/images/content/sync_fifo/ex7.png)

- CLK8에서 CLK9가 되면서 x[0] 데이터가 최종 read 되었다. 다만 FIFO에서 데이터를 읽는다고 해도 FIFO안에 저장된 데이터가 사라지지는 않는다. 그러나 x[0] 데이터가 덮어 써져도 문제 없는 상태다.

- CLK8에서 CLK9가 되면서 rd_ptr이 최종 1 증가한다. 현재 wr_ptr의 index는 8(1000)이고 rd_ptr의 index는 1(0001)이다. MSB는 다르지만, MSB를 제외한 나머지 비트가 모두 다르지 않기 때문에, 더 이상 full 상태가 아니다.

- 다음 데이터를 읽기 위해 다음 클럭에 rd_ptr을 1 증가 시킨다.

![Internal link preview tooltip](/images/content/sync_fifo/ex8.png)

- CLK9에서 CLK10이 되면서 x[1] 데이터가 최종 read 되었다.

- CLK9에서 CLK10이 되면서 rd_ptr이 최종 1 증가 되었다.

- 현재 rd_ptr의 index는 2이므로 FIFO index 2번에서 데이터를 읽는 중이다.

- 다음 클럭에 rd_ptr을 1 증가 시켜 다음 데이터를 읽을 준비를 한다.

![Internal link preview tooltip](/images/content/sync_fifo/ex9.png)

- CLK14에서 CLK15가 되면서 x[6] 데이터가 최종 read 되었다.

- CLK14에서 CLK15가 되면서 rd_ptr이 최종 1 증가 되었다.

- 현재 rd_ptr의 index는 7이므로 FIFO index 7번에서 데이터를 읽는 중이다.


![Internal link preview tooltip](/images/content/sync_fifo/ex10.png)

- CLK15에서 CLK16이 되면서 x[7] 데이터가 최종 read 되었다.

- CLK15에서 CLK16이 되면서 rd_ptr이 최종 1 증가 되었다.

- 현재 rd_ptr의 index는 8이다. 그리고 rd_ptr과 wr_ptr의 index가 서로 같다. 이 경우 FIFO는 empty 상태에 있다.

- 다음 데이터를 쓰기 위해 다음 클럭에 wr_ptr의 데이터를 1 증가 시킨다.

- x[8] 데이터를 FIFO에 쓰는 중이다. 현재 wr_ptr의 index는 8(1000)인데 사실 wr_ptr의 하위 3비트를 보고 FIFO index를 결정한다. MSB 비트는 Full 상태를 판단하기 위한 추가 비트다. 따라서 FIFO index 0에 wr_ptr을 쓰는중이다.

![Internal link preview tooltip](/images/content/sync_fifo/ex11.png)

- CLK16에서 CLK17이 되면서 x[8] 데이터가 최종 write 되었다.

- CLK16에서 CLK17이 되면서 wr_ptr이 최종 1 증가 되었다.

- 동시에 현재 wr_ptr에 x[9] 데이터를 write하는 중이다.

- 다음 데이터를 쓰기 위해 다음 클럭에 wr_ptr을 1 증가 시킨다.

## 3. Verilog RTL 구현

위 예제를 참고하여 RTL로 구현해보자.

```Verilog
module lib_axis_fifo_sync
#(  parameter DW = 8,
    parameter FIFO_DEPTH = 8,    // FIFO DEPTH must be power of 2
    parameter MASTER_DELAY = 1   // Operating like skid buffer
                                 // Master data transfer operate depends on s_axis_tready
                                 // MASTER_DELAY is 1
                                 // Master data transfer operate depends on s_axis_tready -1d
                                 // MASTER_DELAY is 2
)
(
    input                   s_axis_clk,
    input                   s_axis_resetn,

    // Master Interface
    input                   s_axis_tvalid,
    input signed [DW-1:0]   s_axis_tdata,
    output                  s_axis_tready,

    // Slave Interface
    output                  m_axis_tvalid,
    output signed [DW-1:0]  m_axis_tdata,
    input                   m_axis_tready,

    //Status
    output                  o_empty,
    output                  o_full,
    output                  o_almost_full, // This Signal is asserted when FIFO becomes full before 1 clock
    output                  o_overflow
);

reg [$clog2(FIFO_DEPTH):0] rd_ptr;
reg [$clog2(FIFO_DEPTH):0] wr_ptr;

reg signed [DW-1:0] fifo [0:FIFO_DEPTH-1];
reg r_overflow;


integer j;

always @(posedge s_axis_clk) begin
    if(!s_axis_resetn) begin
        rd_ptr <= 0;
    end
    else if(m_axis_tready && !o_empty) begin
        rd_ptr <= rd_ptr + 1;
    end
end

always @(posedge s_axis_clk) begin
    if(!s_axis_resetn) begin
        wr_ptr <= 0;
    end
    else if(s_axis_tvalid && !o_full && s_axis_tready) begin
        wr_ptr <= wr_ptr + 1;
    end
end

wire [$clog2(FIFO_DEPTH):0] wr_ptr_next = wr_ptr + $unsigned(MASTER_DELAY);

always @(posedge s_axis_clk) begin
    if(!s_axis_resetn) begin
        r_overflow <= 0;
    end
    else if(s_axis_tvalid && s_axis_tready && o_full) begin
        r_overflow <= 1;
    end
    else begin
        r_overflow <= 0;
    end
end
always @(posedge s_axis_clk) begin
    if(!s_axis_resetn) begin
        for(j = 0; j < FIFO_DEPTH; j = j+1) begin
            fifo[j] <= 0;
        end
    end
    else if(s_axis_tvalid && s_axis_tready) begin
        fifo[wr_ptr[$clog2(FIFO_DEPTH)-1:0]] <= s_axis_tdata;
    end
end

reg signed [DW-1:0] r_rdata;
always @(posedge s_axis_clk) begin
    if(!s_axis_resetn) begin
        r_rdata <= 0;
    end
    else if(m_axis_tready) begin
        r_rdata <= fifo[rd_ptr[$clog2(FIFO_DEPTH)-1:0]];
    end
end

reg m_axis_tready_1d;
reg o_empty_1d;
always @(posedge s_axis_clk) begin
    if(!s_axis_resetn) begin
        m_axis_tready_1d <= 0;
        o_empty_1d <= 0;
    end
    else begin
        m_axis_tready_1d <= m_axis_tready;
        o_empty_1d <= o_empty;
    end
end

assign m_axis_tdata = r_rdata;
assign m_axis_tvalid = m_axis_tready_1d && !o_empty_1d;
assign o_empty = (rd_ptr == wr_ptr);
assign o_full = (rd_ptr[$clog2(FIFO_DEPTH)]!=wr_ptr[$clog2(FIFO_DEPTH)]) & (rd_ptr[$clog2(FIFO_DEPTH)-1:0] == wr_ptr[$clog2(FIFO_DEPTH)-1:0]);
assign o_overflow = r_overflow;
assign o_almost_full = (rd_ptr[$clog2(FIFO_DEPTH)]!=wr_ptr_next[$clog2(FIFO_DEPTH)]) & (rd_ptr[$clog2(FIFO_DEPTH)-1:0] == wr_ptr_next[$clog2(FIFO_DEPTH)-1:0]);
assign s_axis_tready = !o_full;

endmodule
```

## 5. Example Design

axis_fifo_sync를 활용하여 Example Design을 설계해보자.

Design Example을 구성하는 모듈은 총 5개이다.

- fifo_data_gen.v : FIFO에게 쓸 데이터를 생성하는 MASTER 모듈이다.

- lib_axis_fifo_sync.v : FIFO가 구현된 모듈이다.

- export_data.v : FIFO에서 데이터를 읽는 FIFO의 SLAVE 모듈이다.

- tb.v : Testbench 파일이다.

- lib_clk_rst_gen.v : 클럭 및 초기 reset을 생성하는 모듈이다.

위 5개의 모듈을 Vivado 프로젝트에 복사해서 Example Design을 만들 수 있다.

### 5.1 tb.v
```verilog
`timescale 1ns/1ps

module tb_lib_sync_fifo;

    wire clk;
    wire rst;
    reg i_wen;
    reg i_ren;
    reg signed [3:0] i_wdata;
    reg i_valid;
    wire signed [3:0] o_rdata;
    wire w_valid;
    wire w_empty;
    wire w_full;
    wire w_almost_full;
    wire w_fifo_ready;


    wire w_fifo_valid;
    wire [4:0] w_fifo_data;
    //Data Gen Module
    fifo_data_gen u_fifo_data_gen
    (
        .clk(clk),
        .rst(rst),
        .i_fifo_ready(w_fifo_ready),
        .o_fifo_valid(w_fifo_valid),
        .o_fifo_data(w_fifo_data)
    );

    //FIFO
    wire w_fifo_ren;

    lib_axis_fifo_sync 
    #(.DW(4), .FIFO_DEPTH(8), .MASTER_DELAY(1))
    u_fifo (
        .s_axis_clk(clk),
        .s_axis_resetn(!rst),

        .s_axis_tvalid(w_fifo_valid),
        .s_axis_tdata(w_fifo_data),
        .s_axis_tready(w_fifo_ready),

        .m_axis_tvalid(w_valid),
        .m_axis_tdata(o_rdata),
        .m_axis_tready(w_fifo_ren),

        .o_empty(w_empty),
        .o_full(w_full),
        .o_almost_full(w_almost_full),
        .o_overflow()
    );

    //Data Export Module
    export_data u_export_data
    (
        .clk(clk),
        .rst(rst),
        .i_valid(w_valid),
        .i_data(o_rdata),
        .i_fifo_empty(w_empty),
        .o_fifo_ren(w_fifo_ren)
    );

    // Clock 생성
    lib_clk_rst_gen
    #(.CLK_RATE(200), .RST_CYCLE(2.4))
    u_clk_rst_gen
    (
        .o_clk(clk),
        .o_rst(rst)
    );
endmodule

```
### 5.2 lib_clk_rst_gen.v
```verilog
module lib_clk_rst_gen
#(
    parameter real CLK_RATE  = 200, //MHz
    parameter real RST_CYCLE = 1
)
(
    output o_clk,
    output o_rst
);

reg r_clk = 1;
reg r_rst = 1;

localparam real CLK_PERIOD = 1000/CLK_RATE;

always #(CLK_PERIOD/2) r_clk = ~r_clk;
initial begin
    repeat(RST_CYCLE) @(posedge o_clk);
    r_rst = 0;
end

assign o_clk = r_clk;
assign o_rst = r_rst;

endmodule

```

### 5.3 fifo_data_gen.v
```verilog
module fifo_data_gen(
    input clk,
    input rst,
    input i_fifo_ready,
    output reg o_fifo_valid,
    output reg signed [4:0] o_fifo_data
);

reg [14:0] cnt;
always @(posedge clk) begin
    if(rst) begin
        cnt <= 0;
    end
    else begin
        cnt <= cnt + 1;
    end
end

always @(posedge clk) begin
    if(rst) begin
        o_fifo_valid <= 0;
    end
    else if(cnt < 70) begin
        o_fifo_valid <= 1;
    end
    else begin
        o_fifo_valid <= 0;
    end
end

always @(posedge clk) begin
    if(rst) begin
        o_fifo_data <= 0;
    end
    else if(i_fifo_ready) begin
        o_fifo_data <= o_fifo_data + 1;
    end
    else begin
        o_fifo_data <= o_fifo_data;
    end
end
```

### 5.4 export_data.v
```verilog
module export_data(
    input clk,
    input rst,
    input i_valid,
    input signed [3:0] i_data,
    input i_fifo_empty,
    output reg o_fifo_ren
);

reg [13:0] cnt = 0;
always @(posedge clk) begin
    if(rst) begin
        cnt <= 0;
    end
    else begin
        cnt <= cnt + 1;
    end
end

always @(posedge clk) begin
    if(rst) begin
        o_fifo_ren <= 0;
    end
    else if(cnt < 60 && cnt[5] == 1) begin
        o_fifo_ren <= 1;
    end
    else if(cnt < 80 && cnt[5] == 1) begin
        o_fifo_ren <= 1;
    end
    else if(cnt < 160 && cnt[5] == 1) begin
        o_fifo_ren <= 1;
    end
    else begin
        o_fifo_ren <= 0;
    end
end

reg signed [4:0] r_fifo_1d;
always @(posedge clk) begin
    if(rst) begin
        r_fifo_1d <= 0;
    end
    else if(i_valid) begin
        r_fifo_1d <= i_data;
    end
end

```

## 6. AXI4-Stream Timing 분석
![Internal link preview tooltip](/images/content/sync_fifo/timing1.png)

- o_fifo_valid는 MASTER 모듈에서 FIFO로 전달되는 데이터의 유효성을 나타낸다. MASTER의 valid신호는 SLAVE의 s_axis_tready와 무관하게 동작해야 한다. MASTER가 유효한 데이터를 만들면 그대로 valid신호를 만들어야 한다.

- o_fifo_data는 s_axis_tready와 유관하게 동작해야 한다. s_axis_tready가 1이 되면 값을 증가시킨다. 그렇지 않으면 값을 변화시키지 않고 들고 있어야 한다.

- FIFO에 저장되는 데이터는 s_axis_tvalid와 s_axis_tready가 동시에 1일 때 Handshake가 발생하여 다음 클럭에 FIFO에 최종 저장된다.
데이터 9는 Handshake가 발생하지 않아, FIFO에 저장되지 않는다.

- o_full = 1 일 때, FIFO는 full이다. 따라서 같은 타이밍에 s_axis_tready = 0이 된다. MASTER는 s_axis_tready를 보고 데이터를 증가시키는데, s_axis_tready가 0이므로 다음 클럭에 더 이상 데이터가 증가하지 않는다. 그리고 데이터 9를 계속 유지한다. 유지하는 데이터 역시 유효하므로 o_fifo_valid가 1로 유지된다.

- FIFO의 full이 풀린 순간, s_axis_tready는 동시에 1이 되어 data_gen에서 유지하고 있던 값 9를 다시 FIFO에 넣고, 다음 클럭에 데이터를 9에서 10으로 증가시킨다.

![Internal link preview tooltip](/images/content/sync_fifo/timing2.png)

- m_axis_tready는 export_data가 데이터를 받을 준비가 되었다는 신호다. FIFO는 m_axis_tready를 보고 다음 클럭에 fifo에서 데이터를 빼 m_axis_tvalid를 1로 만든다.
## 7. Vivado 합성 결과 Logic


&nbsp;

![Internal link preview tooltip](/images/content/sync_fifo/syn_fifo.png)
