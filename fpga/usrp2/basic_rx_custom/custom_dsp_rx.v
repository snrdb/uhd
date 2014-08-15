//
// Copyright 2012 Ettus Research LLC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

//COPY ME, CUSTOMIZE ME...

//The following module effects the IO of the DDC chain.
//By default, this entire module is a simple pass-through.

//To implement DSP logic before the DDC:
//Implement custom DSP between frontend and ddc input.

//To implement DSP logic after the DDC:
//Implement custom DSP between ddc output and baseband.

//To bypass the DDC with custom logic:
//Implement custom DSP between frontend and baseband.

module custom_dsp_rx
#(
    //frontend bus width
    parameter WIDTH = 24
)
(
    //control signals
    input clock, //dsp clock
    input reset, //active high synchronous reset
    input clear, //active high on packet control init
    input enable, //active high when streaming enabled

    //user settings bus, controlled through user setting regs API
    input set_stb, input [7:0] set_addr, input [31:0] set_data,

    //full rate inputs directly from the RX frontend
    input [WIDTH-1:0] frontend_i,
    input [WIDTH-1:0] frontend_q,

    //full rate outputs directly to the DDC chain
    output [WIDTH-1:0] ddc_in_i,
    output [WIDTH-1:0] ddc_in_q,

    //strobed samples {I16,Q16} from the RX DDC chain
    input [31:0] ddc_out_sample,
    input ddc_out_strobe, //high on valid sample
    output ddc_out_enable, //enables DDC module

    //strobbed baseband samples {I16,Q16} from this module
    output [31:0] bb_sample,
    output bb_strobe //high on valid sample
);

	wire [7:0] cosine;
	wire [32:0] antialiased;
	wire [23:0] if_5MHz;
	dds_compiler_v4_0 cos_35MHz (
	.clk(clock), // input clk
	.cosine(cosine), // output [7 : 0] cosine
	.sine()); // output [7 : 0] sine

fir_compiler_v5_0 antialias_filter (
        .clk(clock), // input clk
        .rfd(), // output rfd
        .rdy(), // output rdy
        .din(frontend_q[23:8]), // input [15 : 0] din
        .dout(antialiased)); // output [32 : 0] dout


	multiplier if_mult (
 	.clk(clock), // input clk
  	.a(cosine), // input [7 : 0] a
  	.b(antialiased[32:17]), // input [15 : 0] b
  	.p(if_5MHz) // output [23 : 0] p
);

	assign ddc_in_q = if_5MHz;
	assign ddc_in_i = if_5MHz;
//	assign ddc_in_i = {signal_6MHz, 10'b0};
//    assign ddc_in_i = frontend_i;
//    assign ddc_in_q = frontend_q;

    assign bb_sample = ddc_out_sample;
    assign bb_strobe = ddc_out_strobe;
    assign ddc_out_enable = enable;

endmodule //custom_dsp_rx
