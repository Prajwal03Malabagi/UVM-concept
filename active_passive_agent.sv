import uvm_pkg::*;
`include "uvm_macros.svh"
interface intf();
	logic [3:0]a,b;
endinterface

class conf extends uvm_object;
	`uvm_object_utils(conf)
	function new(string name="conf");
		super.new(name);
	endfunction	
	virtual intf vif;
	int num=4;
	uvm_active_passive_enum is_active=UVM_ACTIVE;
endclass


class tx extends uvm_sequence_item;
	`uvm_object_utils(tx)
	function new(string name="tx");
		super.new(name);
	endfunction
	
	rand bit[3:0]a,b;
endclass

class seq extends uvm_sequence #(tx);
	`uvm_object_utils(seq)
	function new(string name="seq");
		super.new(name);
	endfunction

	task body();
		repeat(2)
		begin	
			req = tx::type_id::create("req");
			start_item(req);
			req.randomize();
			finish_item(req);
		end
	endtask
endclass

class seqr extends uvm_sequencer #(tx);
	`uvm_component_utils(seqr)
	function new(string name="seqr",uvm_component parent);
		super.new(name,parent);
	endfunction
endclass

class driver extends uvm_driver #(tx);
	`uvm_component_utils(driver);
	virtual intf vif;
	conf cf;
	
	function new(string name="driver",uvm_component parent);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		if(!uvm_config_db#(conf)::get(this,"","hi",cf))
			`uvm_fatal("driver","mission failed")
	endfunction

	function void connect_phase(uvm_phase phase);
		vif=cf.vif;
	endfunction

	task run_phase(uvm_phase phase);
		forever begin
			seq_item_port.get_next_item(req);
				drive(req);
			seq_item_port.item_done();
		end
	endtask
	task drive(tx t);
		vif.a<=t.a;
		vif.b<=t.b;
	endtask
endclass

class monitor extends uvm_monitor;
	`uvm_component_utils(monitor)
	
	function new(string name="monitor",uvm_component parent);
		super.new(name,parent);
	endfunction
		
endclass

class agent extends uvm_agent;
	`uvm_component_utils(agent)
	seqr sqr;
	driver drv;
	monitor mon;
	conf cf;
	function new(string name="agent",uvm_component parent);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		if(!uvm_config_db#(conf)::get(this,"","hi",cf))
			`uvm_fatal("agent","failed")

		mon=monitor::type_id::create("mon",this);
		if(cf.is_active==UVM_ACTIVE)begin
			drv=driver::type_id::create("drv",this);
			sqr=seqr::type_id::create("sqr",this);
		end
	endfunction
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		if(cf.is_active==UVM_ACTIVE)
			drv.seq_item_port.connect(sqr.seq_item_export);
	endfunction
endclass

class env extends uvm_env;
	`uvm_component_utils(env)
	agent ag[];
	conf cf;
	int i;
	function new(string name="env",uvm_component parent);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		ag = new[4];
 		for (i = 0; i < 4; i++) begin
    			ag[i] = agent::type_id::create($sformatf("ag[%0d]", i), this);
  		end
	//	for( i=0;i<4;i++) //;
	//		ag[0]=agent::type_id::create($sformatf("a[%d]",i),this);
		endfunction
endclass

class test extends uvm_test;
	`uvm_component_utils(test)
	env e;
	conf cf1,cf2,cf3,cf4;
	seq se;
	virtual intf vif;
	function new(string name="test",uvm_component parent);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);

		if(!uvm_config_db#(virtual intf)::get(this,"","hii",vif))
			`uvm_fatal("test","mission failed")
		
		se=seq::type_id::create("se",this);
		e=env::type_id::create("e",this);
		cf1=conf::type_id::create("cf1");
		cf2=conf::type_id::create("cf2");
		cf3=conf::type_id::create("cf3");
		cf4=conf::type_id::create("cf4");
		cf1.is_active=UVM_ACTIVE;cf1.vif=vif;
		cf2.is_active=UVM_ACTIVE;cf2.vif=vif;
		cf3.is_active=UVM_PASSIVE;cf3.vif=vif;
		cf4.is_active=UVM_ACTIVE;cf4.vif=vif;

		uvm_config_db#(conf)::set(this,"e.ag[0]*","hi",cf1);
		uvm_config_db#(conf)::set(this,"e.ag[1]*","hi",cf2);
		uvm_config_db#(conf)::set(this,"e.ag[2]*","hi",cf3);
		uvm_config_db#(conf)::set(this,"e.ag[3]*","hi",cf4);

	endfunction
	function void end_of_elaboration_phase(uvm_phase phase);
		uvm_top.print_topology();
	endfunction
	
	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
	//	for(int i=0;i<cf1.num;i++)
	//		se.start(e.ag[i].sqr);
		for (int i = 0; i < 4; i++) begin
      			if (e.ag[i].cf.is_active == UVM_ACTIVE) begin
        	//	seq se_i;
        		se = seq::type_id::create($sformatf("se_%0d", i));
        		se.start(e.ag[i].sqr);
      			end
   	 	end
		phase.drop_objection(this);
	endtask
endclass


module top();
	intf vif();
	
	initial begin
		uvm_config_db#(virtual intf)::set(null,"*","hii",vif);
		run_test("test");
	end
endmodule
	
