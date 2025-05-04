---
title: "lib_axis_fifo_async.v"
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
Asynchronous FIFO에 대한 개념을 설명하고 AXI4-Stream 인터페이스에 맞게 RTL로 구현하는 과정을 기술한다.

Synchornous FIFO의 이해가 없다면 해당 게시물의 내용이 이해가 안 갈 것이므로, 왼쪽 링크에서 먼저 Sync FIFO의 개념을 이해하고 오자. ([Synchornous FIFO 참고 링크)](https://egghwan.github.io/docs/rtl-ip/lib_sync_fifo/)

## 1. CDC(Clock-Domaing-Crossing) 개념

데이터를 처리하는 클럭의 속도가 달라질 때, CDC가 발생한다고 말한다.

CDC가 생길 때 가장 큰 문제가 발생하는 부분은, Metastability가 발생한다는 점이다. 아래 그림을 통해 CDC의 개념을 알아보자.

&nbsp;

![Internal link preview tooltip](/images/content/async_fifo/meta.png)  

CLKA와 CLKB는 서로 다른 주파수의 클럭이다. DA데이터는 CLKA에 동기화 되어 있다. DA를 낮은 주파수의 CLKB로 처리하기 위해서 CDC가 발생하는 가정을 들어보자.

DA는 CLKA의 1클럭동안 유효한 데이터이고 1클럭이 지나면 0으로 떨어진다. 이 때, DA가 0으로 값이 떨어지는 도중에 CLKB의 상승 엣지가 발생했다.

이 때 CLKB 도메인으로 옮겨진 DA 데이터는 0일까? 1일까? 답은 애매하다. 이러한 상태를 Metastability(Meta)라고 표현한다. 

Meta를 해결하기 위해 다양한 CDC 기법이 존재한다.

## 2. 2-FF Synchronizer

가장 대표적으로 데이터를 CDC할 수 있는 2-FF Synchronizer에 대해 알아보자.

![Internal link preview tooltip](/images/content/async_fifo/2ff.png)  

F/F은 데이터를 저장할 수 있는 하드웨어다. Old Clock domain에서 New Clock Domain으로 데이터를 CDC 처리할 때, 단순히 F/F을 2개 연달아서 배치하면 된다.

이럴 경우 새로운 클럭으로 2clk이 delay된 신호를 최종 사용하기 때문에 Metastabilty 상태에서 벗어난 데이터를 안정적으로 사용할 수 있다.

2-F/F Synchronizer를 활용해 Async FIFO를 설계할 수 있다.

## 3. Gray Pointer vs Binary Pointer

여러 비트 넓이의 데이터를 CDC 처리를 하기 위해 Asynchronous FIFO가 가장 많이 사용된다.

Asynchronous FIFO와 Synchronous FIFO의 가장 큰 차이는 데이터를 Write하는 클럭과 데이터를 Read하는 클럭이 서로 다르다는 것이다.

Synchronous FIFO에 사용된 포인터는 Binary Pointer이다. 말 그대로 포인터를 이진법으로 나타낸 것이다.

4비트 포인터 기준으로, 0은 0000, 1은 0001, 2는 0010, 3은 0011 순이다. 그러나 Binary Pointer를 사용하면 1에서 2로 넘어갈 때, 3번째, 4번째 비트가 바뀐다.

즉 총 2개의 비트가 바뀌게 된다. 이렇게 포인터가 증가함에 따라 많은 비트가 바뀐다면 CDC처리에서 오류가 발생할 확률이 높아진다.

이를 해결하기 위해서 Async FIFO에서는 Gray Pointer를 사용한다. 아래 그림은 Gray Pointer의 예다. 

![Internal link preview tooltip](/images/content/async_fifo/gray_pointer.png)  

0은 0000, 1은 0001, 2는 0011, 3은 0010 순으로 값이 바뀌게 된다.

Binary Pointer와 가장 큰 차이는 값이 바뀜에 따라 비트가 1개만 바뀐다. 이렇게 변화하는 비트의 개수를 최소화하여 CDC 처리에 위험을 줄일 수 있다.

그러면 Binary Pointer를 Gray Pointer로 바꾸기 위해서 어떻게 해야 할 까?

답은 간단하다. Binary Pointer를 1비트 왼쪽으로 비트 이동을 한 것과 원래의 Binary Pointer를 xor 취하면 된다.

Bianry Pointer 2를 예로 들어보자.

원래의 Binary Pointer는 0010이고, 1비트 왼쪽으로 비트 이동한 것은 0001이다.

0010 (xor) 0001 = 0011이 된다.

이제 Async FIFO에 사용하는 모든 Pointer는 Gray Pointer를 사용해 값을 쓰거나 읽게 된다.

## 4. Gray Pointer의 CDC 처리

Binary Pointer를 Gray Pointer로 바꾼 뒤 Metastabilty 상태를 없애기 위해서 2-ff Synchronizer를 사용한다.

Old Clock(Write Clock) domain의 쓰기 Gray 포인터를 2-ff synchronizer를 거쳐 New Clock(Read Clock) Domain의 쓰기 Gray 포인터를 만들어 준다.

반대로 New Clock(Read Clock) Domain의 읽기 Gray 포인터를 2-ff synchronizer를 거쳐 Old Clock(Write Clock) Domain으로 바꿔준다. 아래 그림을 참고하자.

![Internal link preview tooltip](/images/content/async_fifo/2ff_pointer.png)  

이제 Write Clock Domain과 Read Clock Domain에서 쓰기 포인터와 읽기 포인터의 값을 비교할 수 있다.

이를 활용해서 Asnyc FIFO full과 empty상태를 판단할 수 있다.

## 5. FULL 과 EMPTY 상태 판단

먼저 FULL상태를 판단해보자.

FULL은 FIFO에 데이터를 쓰는 행위와 관련이 있다. FULL일 때 더 이상 데이터를 쓰지 못하기 때문이다.

따라서 읽기 포인터와 쓰기 포인터를 Write Clock Domain에서 비교한다. 비교를 위해 읽기 포인터를 Write Clock Domain으로 바꾼다.

즉 wr_ptr_wclk과 rd_ptr_wclk을 비교하여 FULL 상태를 비교한다.

Sync FIFO와 다른점은 포인터의 형태가 Gray 포인터 형태기 때문에, 포인터를 다시 Binary Pointer로 바꿔서 비교하거나, 다른 방법을 사용해야 한다. 
 
Gray Pointer를 Binary Pointer로 다시 바꾸는 것은 하드웨어 구현시 추가 로직이 발생하므로, Gray Pointer 상에서 비교한다.

Sync FIFO에서 FULL은 Binary Pointer의 MSB가 다르고 MSB를 제외한 비트가 모두 같을 때다.

예를 들어 Sync FIFO의 읽기 포인터가 0010이고 쓰기 포인터가 1010일 때 FIFO는 full이다.

만약 Sync FIFO가 Gray Pointer를 사용했다면 0010은 0011이고, 1010은 1111이다.

0011과 1111을 비교해보면 상위 2비트는 다르고 나머지 2비트는 같다.

즉 Gray Pointer에서는 Binary Pointer와 달리, 상위 2비트가 다르고, 상위 2비트를 제외한 나머지 비트가 같을 때 FULL 상태다.

다음으로 EMPTY 상태를 판단해보자.

EMPTY는 FIFO에 데이터를 읽는 행위와 관련이 있다. 따라서 Read Clock Domain에서 읽기 포인터와 쓰기 포인터를 비교한다.

Sync FIFO의 경우 읽기 포인터와 쓰기 포인터가 같을 때, EMPTY상태다.

Async FIFO도 마찬가지다. Gray포인터의 형태의 쓰기 포인터와 읽기 포인터가 같을 때 EMPTY 상태다.

다만 포인터를 비교할 때 Read Clock Domain에서 비교해야 한다. 이를 위해 쓰기 포인터를 Read Clock Domain으로 CDC 처리를 한 후, 비교를 진행한다.

## 6. RTL 설계 고려 사항

위 내용을 정리하면 아래와 같다.

1. FIFO의 Write 포인터와 Read 포인터를 Gray 포인터 형태로 바꾼다.

2. FIFO의 FULL상태는 Write Clock Domain에서 비교해아한다. 이를 위해 Gray Pointer 형태의 Read Pointer를 2-ff Synchronizer를 통해 Write Clock Domain으로 바꾼다.

3. Gray Pointer 형태의 Write 포인터와 Read 포인터의 상위 2비트를 비교해 그 2비트가 서로 달라야하고, 나머지 비트는 서로 같을 때 FULL이다.

4. FIFO의 EMPTY 상태는 Read Clock Domain에서 비교해야한다. 이를 위해 Gray Pointer 형태의 Write Pointer를 2-ff Synchronizer를 통해 Read Clock Domain으로 바꾼다.

5. Gray Pointer 형태의 Write 포인터와 Read 포인터가 서로 같을 때, EMPTY다.


## 7. Verilog RTL 구현
```verilog
module lib_axis_fifo_async
#(
    parameter DW =8,
    parameter FIFO_DEPTH = 8
)
(    
    // Master Interfaces
    input                   s_axis_wclk,        // Write CLK
    input                   s_axis_resetn,
    input                   s_axis_tvalid,
    input signed [DW-1:0]   s_axis_tdata,
    output                  s_axis_tready,

    // Slave Interfaces
    input                   m_axis_rclk,        // Read CLK
    input                   m_axis_resetn,
    output                  m_axis_tvalid,
    output signed [DW-1:0]  m_axis_tdata,
    input                   m_axis_tready,

    // Status
    output                  o_empty,
    output                  o_full,
    output                  o_overflow
);

reg signed [DW-1:0] fifo [0:FIFO_DEPTH-1];
reg r_overflow;

always @(posedge s_axis_wclk) begin
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

// Write CLK Domain
reg [$clog2(FIFO_DEPTH):0] wr_ptr_bin;
wire [$clog2(FIFO_DEPTH):0] wr_ptr_gray;
reg [$clog2(FIFO_DEPTH):0] rd_ptr_gray_meta;
reg [$clog2(FIFO_DEPTH):0] rd_ptr_gray_wclk;

always @(posedge s_axis_wclk) begin
    if(!s_axis_resetn) begin
        wr_ptr_bin <= 0;
    end
    else if(s_axis_tvalid && !o_full && s_axis_tready) begin
        wr_ptr_bin <= wr_ptr_bin + 1;
    end
end

assign wr_ptr_gray = bin2gray(wr_ptr_bin);

// Read CLK Domain
reg [$clog2(FIFO_DEPTH):0] rd_ptr_bin;
wire [$clog2(FIFO_DEPTH):0] rd_ptr_gray;
reg [$clog2(FIFO_DEPTH):0] wr_ptr_gray_meta;
reg [$clog2(FIFO_DEPTH):0] wr_ptr_gray_rclk;

// CDC - wr_ptr
always @(posedge m_axis_rclk) begin
    if(!m_axis_resetn) begin
        wr_ptr_gray_meta <= 0;
        wr_ptr_gray_rclk <= 0;
    end
    else begin
        wr_ptr_gray_meta <= wr_ptr_gray;
        wr_ptr_gray_rclk <= wr_ptr_gray_meta;
    end
end

// Read Clock Domain
always @(posedge m_axis_rclk) begin
    if(!m_axis_resetn) begin
        rd_ptr_bin <= 0;
    end
    else if(m_axis_tready && !o_empty) begin
        rd_ptr_bin <= rd_ptr_bin + 1;
    end
end

assign rd_ptr_gray = bin2gray(rd_ptr_bin);

// CDC - rd_ptr
always @(posedge s_axis_wclk) begin
    if(!m_axis_resetn) begin
        rd_ptr_gray_meta <= 0;
        rd_ptr_gray_wclk <= 0;
    end
    else begin
        rd_ptr_gray_meta <= rd_ptr_gray;
        rd_ptr_gray_wclk <= rd_ptr_gray_meta;
    end
end

// Write Clock Domain
integer k;

always @(posedge s_axis_wclk) begin
    if(!s_axis_resetn) begin
        for(k = 0; k < FIFO_DEPTH; k = k+1) begin
            fifo[k] <= 0;
        end
    end
    else if(s_axis_tvalid && s_axis_tready) begin
        fifo[wr_ptr_bin[$clog2(FIFO_DEPTH)-1:0]] <= s_axis_tdata;
    end
end

// Read Clock Domain
reg signed [DW-1:0] r_rdata;
always @(posedge m_axis_rclk) begin
    if(!m_axis_resetn) begin
        r_rdata <= 0;
    end
    else if(m_axis_tready) begin
        r_rdata <= fifo[rd_ptr_bin[$clog2(FIFO_DEPTH)-1:0]];
    end
end

reg m_axis_tready_1d;
reg o_empty_1d;
always @(posedge m_axis_rclk) begin
    if(!m_axis_resetn) begin
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
assign o_empty = (rd_ptr_gray == wr_ptr_gray_rclk);
assign o_full = (wr_ptr_gray[$clog2(FIFO_DEPTH)] != rd_ptr_gray_wclk[$clog2(FIFO_DEPTH)]) && 
                (wr_ptr_gray[$clog2(FIFO_DEPTH)-1] != rd_ptr_gray_wclk[$clog2(FIFO_DEPTH)-1]) && 
                (wr_ptr_gray[$clog2(FIFO_DEPTH)-2:0]) == rd_ptr_gray_wclk[$clog2(FIFO_DEPTH)-2:0];
assign s_axis_tready = !o_full;
assign o_overflow = r_overflow;

function [$clog2(FIFO_DEPTH):0] bin2gray;
    input [$clog2(FIFO_DEPTH):0] bin;
    begin
       bin2gray = (bin>>1) ^ bin;
    end
 endfunction

endmodule

```

## 8. Example Design

axis_fifo_async를 활용해서 Example Design을 설계해보자.

Design Example을 구성하는 모듈은 총 5개다.

-- fifo_data_gen.v : FIFO에게 쓸 데이터를 생성하는 MASTER 모듈이다.

-- lib_axis_fifo_async.v : Async FIFO가 구현된 모듈이다.

-- export_data.v : FIFO에서 데이터를 읽는 FIFO SLAVE 모듈이다.

-- tb.v : Testbench 파일이다.

-- lib_clk_rst_gen.v : Write CLK, Read CLK 및 초기 reset을 생성하는 모듈이다.

위 5개의 모듈을 Vivado 프로젝트에 복사해서 Example Design을 만들 수 있다.

### 8.1 tb.v
```verilog
`timescale 1ns/1ps

module tb_lib_sync_fifo;

    wire clk_wr;
    wire rst_wr;
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
        .clk_wr(clk_wr),
        .rst_wr(rst_wr),
        .i_fifo_ready(w_fifo_ready),
        .o_fifo_valid(w_fifo_valid),
        .o_fifo_data(w_fifo_data)
    );

    //FIFO
    wire w_fifo_ren;

    lib_axis_fifo_async 
    #(.DW(4), .FIFO_DEPTH(8), .MASTER_DELAY(1))
    u_fifo (
        .s_axis_wclk(clk_wr),
        .s_axis_resetn(!rst_wr),

        .s_axis_tvalid(w_fifo_valid),
        .s_axis_tdata(w_fifo_data),
        .s_axis_tready(w_fifo_ready),

        .m_axis_rclk(clk_rd),
        .m_axis_resetn(!rst_rd),
        .m_axis_tvalid(w_valid),
        .m_axis_tdata(o_rdata),
        .m_axis_tready(w_fifo_ren),

        .o_empty(w_empty),
        .o_full(w_full),
        .o_overflow()
    );

    //Data Export Module
    export_data u_export_data
    (
        .clk_rd(clk_rd),
        .rst_rd(rst_rd),
        .i_valid(w_valid),
        .i_data(o_rdata),
        .i_fifo_empty(w_empty),
        .o_fifo_ren(w_fifo_ren)
    );

    // Clock 생성
    lib_clk_rst_gen
    #(.CLK_RATE(200), .RST_CYCLE(2.4))
    u_clk_wr_rst_gen
    (
        .o_clk(clk_wr),
        .o_rst(rst_wr)
    );

    lib_clk_rst_gen
    #(.CLK_RATE(140), .RST_CYCLE(2.4))
    u_clk_rd_rst_gen
    (
        .o_clk(clk_rd),
        .o_rst(rst_rd)
    );
endmodule
```
### 8.2 lib_clk_rst_gen.v
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

### 8.3 fifo_data_gen.v
```verilog
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/27 15:08:47
// Design Name: 
// Module Name: fifo_data_gen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fifo_data_gen(
    input clk_wr,
    input rst_wr,
    input i_fifo_ready,
    output reg o_fifo_valid,
    output reg signed [4:0] o_fifo_data
);

reg [14:0] cnt;
always @(posedge clk_wr) begin
    if(rst_wr) begin
        cnt <= 0;
    end
    else begin
        cnt <= cnt + 1;
    end
end

always @(posedge clk_wr) begin
    if(rst_wr) begin
        o_fifo_valid <= 0;
    end
    else if(cnt < 170) begin
        o_fifo_valid <= 1;
    end
    else begin
        o_fifo_valid <= 0;
    end
end

always @(posedge clk_wr) begin
    if(rst_wr) begin
        o_fifo_data <= 0;
    end
    else if(i_fifo_ready) begin
        o_fifo_data <= o_fifo_data + 1;
    end
    else begin
        o_fifo_data <= o_fifo_data;
    end
end

endmodule

```
### 8.4 export_data.v
```verilog
module export_data(
    input clk_rd,
    input rst_rd,
    input i_valid,
    input signed [3:0] i_data,
    input i_fifo_empty,
    output reg o_fifo_ren
);

reg [13:0] cnt = 0;
always @(posedge clk_rd) begin
    if(rst_rd) begin
        cnt <= 0;
    end
    else begin
        cnt <= cnt + 1;
    end
end

always @(posedge clk_rd) begin
    if(rst_rd) begin
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
always @(posedge clk_rd) begin
    if(rst_rd) begin
        r_fifo_1d <= 0;
    end
    else if(i_valid) begin
        r_fifo_1d <= i_data;
    end
end

endmodule
```

## 9. Vivado 합성 결과 Logic


![Internal link preview tooltip](/images/content/async_fifo/logci.png)  