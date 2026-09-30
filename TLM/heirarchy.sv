import uvm_pkg::*;
`include "uvm_macros.svh"

class tx extends uvm_sequence_item;
`uvm_object_utils(tx)

rand bit[3:0]a;
rand int b;

constraint c1{a==b;}

function new(string name="tx");
	super.new(name);
endfunction

function void do_print(uvm_printer printer);
	printer.print_field("a",a,4,UVM_BIN);
	printer.print_field("b",b,32,UVM_BIN);
endfunction
endclass

class stim extends uvm_component;
`uvm_component_utils(stim)
uvm_blocking_put_port#(tx)put_port;
tx t;
function new(string name="stim",uvm_component parent);
	super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
	put_port=new("put_port",this);
endfunction

task run_phase(uvm_phase phase);
	repeat(2)
	begin	
		t=tx::type_id::create("t");
		t.randomize();
		put_port.put(t);
		$display("stim");
		t.print();
	end
endtask
endclass

class conv extends uvm_component;
`uvm_component_utils(conv)
uvm_blocking_get_port#(tx)get_port;
uvm_blocking_put_port#(tx)put_port;
tx t;
function new(string name="conv",uvm_component parent);
	super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
	get_port=new("get_port",this);
	put_port=new("put_port",this);
endfunction

task run_phase(uvm_phase phase);
	forever
	begin	
		get_port.get(t);
		$display("conv");
		t.print();
		 put_port.put(t);
	end
endtask
endclass

class producer extends uvm_component;
`uvm_component_utils(producer)
uvm_tlm_fifo#(tx)fifo;
uvm_blocking_put_export#(tx)put_port;
stim s;
conv c;
function new(string name="producer",uvm_component parent);
	super.new(name,parent);
	fifo=new("fifo",this);
	put_port=new("put_port",this);
endfunction

function void build_phase(uvm_phase phase);
	s=stim::type_id::create("s",this);
	c=conv::type_id::create("c",this);
endfunction

function void connect_phase(uvm_phase phase);
	s.put_port.connect(fifo.put_export);
	c.get_port.connect(fifo.get_export);
	c.put_port.connect(this.put_port);
endfunction
endclass

class drive extends uvm_component;
`uvm_component_utils(drive)
uvm_blocking_get_port#(tx)get_port;
tx t;
function new(string name="drive",uvm_component parent);
	super.new(name,parent);
	get_port=new("get_port",this);
endfunction

task run_phase(uvm_phase phase);
	forever begin
	get_port.get(t);
	$display("drive");
	t.print();end
endtask
endclass

class consumer extends uvm_component;
`uvm_component_utils(consumer)
uvm_tlm_fifo#(tx)fifo;
uvm_blocking_put_export#(tx)put_export;
drive d;
function new(string name="consumer",uvm_component parent);
	super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
	fifo=new("fifo",this);
	put_export=new("put_export",this);
	d=drive::type_id::create("d",this);
endfunction

function void connect_phase(uvm_phase phase);
	d.get_port.connect(fifo.get_export);
	this.put_export.connect(fifo.put_export);
endfunction
endclass

class top extends uvm_component;
`uvm_component_utils(top)
producer p;
consumer c;
function new(string name="top",uvm_component parent);
	super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
	p=producer::type_id::create("p",this);
	c=consumer::type_id::create("c",this);
endfunction

function void connect_phase(uvm_phase phase);
	p.put_port.connect(c.put_export);
	uvm_top.print_topology;
endfunction
endclass

module mod;

initial run_test("top");
endmodule
