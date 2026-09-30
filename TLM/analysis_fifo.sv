import uvm_pkg::*;
`include "uvm_macros.svh"

class tx extends uvm_sequence_item;
`uvm_object_utils(tx)
rand bit [2:0]a;
rand bit[4:0]b;

function new(string name="tx");
	super.new(name);
endfunction

function void do_print(uvm_printer printer);
	printer.print_field("a",a,3,UVM_BIN);
	printer.print_field("b",a,5,UVM_BIN);
endfunction

endclass

class comp1 extends uvm_component;
`uvm_component_utils(comp1)
uvm_analysis_port#(tx)port;
tx t;
function new(string name="comp1",uvm_component parent);
	super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
	port=new("port",this);
endfunction

task run_phase(uvm_phase phase);
	repeat(2)
	begin	
		t=tx::type_id::create("t");
		t.randomize();
		t.print();
		port.write(t);
	end
endtask
endclass

class comp2 extends uvm_component;
`uvm_component_utils(comp2)
uvm_tlm_analysis_fifo#(tx)fifo;
function new(string name="comp2",uvm_component parent);
	super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
	fifo=new("get_port",this);
endfunction

task run_phase(uvm_phase phase);
	forever
	begin
		tx t;
		fifo.get(t);
		t.print();
	end
endtask
endclass

class comp3 extends uvm_component;
`uvm_component_utils(comp3)
uvm_analysis_imp#(tx,comp3)imp;
tx t;
function new(string name="comp3",uvm_component parent);
	super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
	imp=new("get_port",this);
endfunction

function void write(tx t);
	this.t=t;
	$display("comp3");
	t.print();
endfunction
endclass


class test extends uvm_test;
`uvm_component_utils(test)
uvm_tlm_analysis_fifo#(tx)fifo1;
comp1 c1;
comp2 c2;
comp3 c3;
function new(string name="test",uvm_component parent);
	super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
//	fifo=new("fifo",this);
	c1=comp1::type_id::create("c1",this);
	c2=comp2::type_id::create("c2",this);
	c3=comp3::type_id::create("c3",this);
endfunction

function void connect_phase(uvm_phase phase);
	c1.port.connect(c2.fifo.analysis_export);
	//c2.get_port.connect(fifo.analysis_export);
	c1.port.connect(c3.imp);
endfunction
endclass

module mod;

initial run_test("test");
endmodule
