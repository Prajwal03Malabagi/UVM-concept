import uvm_pkg::*;
`include "uvm_macros.svh"

class tx extends uvm_sequence_item;
`uvm_object_utils(tx)

function new(string name="tx");
	super.new(name);
endfunction

rand bit [3:0]a;
rand bit [2:0]b;

	constraint c1{a==b;}

	function void do_print(uvm_printer printer);
		printer.print_field("a",a,4,UVM_BIN);
		printer.print_field("b",b,3,UVM_BIN);
	endfunction


endclass

class comp1 extends uvm_component;
`uvm_component_utils(comp1);
uvm_blocking_put_port#(tx) put_port;
tx req;
function new(string name="prajwal",uvm_component parent);
	super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
	put_port=new("put_port",this);
endfunction

task run_phase(uvm_phase phase);
	req=tx::type_id::create("req");
	req.randomize();
	put_port.put(req);
endtask
endclass

class comp2 extends uvm_component;
`uvm_component_utils(comp2)
uvm_blocking_get_port#(tx) get_port;
tx req;
function new(string name="comp2",uvm_component parent);
	super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);	
	get_port=new("fet_port",this);
endfunction

task run_phase(uvm_phase phase);
	get_port.get(req);
	req.print();
endtask
endclass

class test extends uvm_test;
`uvm_component_utils(test)
uvm_tlm_fifo#(tx)fifo;
comp1 c1;
comp2 c2;

function new(string name="test",uvm_component p);
	super.new(name,p);
endfunction

function void build_phase(uvm_phase phase);
	fifo=new("fifo",this);
	c1=comp1::type_id::create("c1",this);
	c2=comp2::type_id::create("c2",this);
endfunction

function void connect_phase(uvm_phase phase);
	c1.put_port.connect(this.fifo.put_export);
	c2.get_port.connect(this.fifo.get_export);
endfunction
endclass

module mod;

initial run_test("test");
endmodule
