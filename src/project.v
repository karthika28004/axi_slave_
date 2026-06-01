/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */
`default_nettype none
module tt_um_axi_slave_receiver (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // AXI Slave Receiver Signal Mapping
  // ui_in[0]   = s_axi_awvalid  (Write Address Valid)
  // ui_in[1]   = s_axi_wvalid   (Write Data Valid)
  // ui_in[2]   = s_axi_arvalid  (Read Address Valid)
  // ui_in[3]   = s_axi_rready   (Read Ready)
  // ui_in[4]   = s_axi_bready   (Write Response Ready)
  // ui_in[7:5] = reserved

  // uio_in[7:0] = s_axi_wdata   (Write Data 8-bit)

  // uo_out[0]  = s_axi_awready  (Write Address Ready)
  // uo_out[1]  = s_axi_wready   (Write Data Ready)
  // uo_out[2]  = s_axi_arready  (Read Address Ready)
  // uo_out[3]  = s_axi_rvalid   (Read Data Valid)
  // uo_out[4]  = s_axi_bvalid   (Write Response Valid)
  // uo_out[5]  = s_axi_bresp    (Write Response)
  // uo_out[6]  = s_axi_rresp    (Read Response)
  // uo_out[7]  = reserved

  // Internal registers
  reg [7:0] mem_reg;        // Memory register to store write data
  reg       awready_reg;
  reg       wready_reg;
  reg       bvalid_reg;
  reg       arready_reg;
  reg       rvalid_reg;
  reg [7:0] rdata_reg;

  // AXI input signals
  wire s_axi_awvalid = ui_in[0];
  wire s_axi_wvalid  = ui_in[1];
  wire s_axi_arvalid = ui_in[2];
  wire s_axi_rready  = ui_in[3];
  wire s_axi_bready  = ui_in[4];
  wire [7:0] s_axi_wdata = uio_in[7:0];

  // AXI Write Address Channel
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      awready_reg <= 1'b0;
    else
      awready_reg <= s_axi_awvalid;
  end

  // AXI Write Data Channel
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wready_reg <= 1'b0;
      mem_reg    <= 8'b0;
    end else begin
      wready_reg <= s_axi_wvalid;
      if (s_axi_wvalid)
        mem_reg <= s_axi_wdata;
    end
  end

  // AXI Write Response Channel
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      bvalid_reg <= 1'b0;
    else if (s_axi_wvalid)
      bvalid_reg <= 1'b1;
    else if (s_axi_bready)
      bvalid_reg <= 1'b0;
  end

  // AXI Read Address Channel
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      arready_reg <= 1'b0;
    else
      arready_reg <= s_axi_arvalid;
  end

  // AXI Read Data Channel
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rvalid_reg <= 1'b0;
      rdata_reg  <= 8'b0;
    end else if (s_axi_arvalid) begin
      rvalid_reg <= 1'b1;
      rdata_reg  <= mem_reg;   // Return stored data
    end else if (s_axi_rready) begin
      rvalid_reg <= 1'b0;
    end
  end

  // Output assignments
  assign uo_out[0] = awready_reg;
  assign uo_out[1] = wready_reg;
  assign uo_out[2] = arready_reg;
  assign uo_out[3] = rvalid_reg;
  assign uo_out[4] = bvalid_reg;
  assign uo_out[5] = 1'b0;     // bresp = OKAY
  assign uo_out[6] = 1'b0;     // rresp = OKAY
  assign uo_out[7] = 1'b0;

  assign uio_out = rdata_reg;   // Read data output
  assign uio_oe  = rvalid_reg ? 8'hFF : 8'h00; // Enable output only during read

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, 1'b0};

endmodule
