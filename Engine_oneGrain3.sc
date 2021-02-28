Engine_oneGrain3 : CroneEngine {


	var <buffer;
	var <recBuffer;
	var <synth;
	var <record;
	var <length;
	var <lengthRec;
	var whichBuf = 1;
	var newbuf;
  var duration = 1;
	var amp = 1;
	var pg;
	var start = 0;
	var pstn = 0;
	var pan = 0.6;
	var pitchDisp = 0;
	var pitchQ = 0;
	var timeDisp = 0;
	var recordButton;
	var startRec;
	var run;
	var overdub;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}
	
//disk read
	readBuf { arg path;
		if(buffer.notNil, {
			if (File.exists(path), {
				  newbuf = Buffer.readChannel(context.server, path, 0, -1, [0], {
					buffer.free;
					buffer = newbuf;
					length = buffer.numFrames;
				});
			});
		});
	}

alloc{	
pg = ParGroup.tail(context.xg);

			
buffer = Buffer.alloc(context.server, context.server.sampleRate * 1);
recBuffer = Buffer.alloc(context.server, context.server.sampleRate * 8.0, 1);
length = recBuffer.numFrames;

	
SynthDef("agrain", { arg out = 0, bufnum = 0, pchRatio = 1, pitchDisp = 0, pitchQ = 0, start = 0,timeDisp = 0, duration, panSpeed = pan, amp = 0.5;
    var playbuf, env1, env2,env3;
	  env1 = Env.linen(0.1,1,0.1,1);
	  env2 = Env.sine(1.1,1);
	  env3 = Env.new([0, 1, 1, 0],[0.125,1,0.125],\welch);
    playbuf = Pan2.ar(PlayBuf.ar(bufnum.numChannels,
                                bufnum,
			                          BufRateScale.kr(bufnum) * pchRatio,
			                          0,
			                          start,
			                          0,
			                          2) * EnvGen.kr(env2,doneAction: 2,timeScale: duration, levelScale: amp),
			        Rand(panSpeed,panSpeed.neg));
    Out.ar(out, playbuf);
	}).add;


SynthDef(\recorder, { arg out = 0, inL, inR, buffer, startFrame = 0, stopGo = 0, overdub = 0.5;
    var soundIn;
    soundIn= In.ar(inL);
    RecordBuf.ar(soundIn, bufnum: recBuffer, offset: startFrame, preLevel: overdub, run: stopGo, doneAction: 0, loop: 1);
}).add;


context.server.sync;

synth = Synth.new(\agrain, [
			\inL, context.in_b[0].index,			
			\inR, context.in_b[1].index,
			\out, context.out_b.index],
		context.xg);
		
record = Synth.new(\recorder, [
			\inL, context.in_b[0].index,			
			\inR, context.in_b[1].index,
			\out, context.out_b.index],
		context.xg);

    
		this.addCommand("recordButton", "i", {|msg|
			record.set(\stopGo, msg[1]);
		  //context.server.queryAllNodes;
		});
		
		this.addCommand("overdub", "f", {|msg|
			record.set(\overdub, msg[1]);
			//context.server.queryAllNodes;
		});
		
		
		this.addCommand("read", "s", { arg msg;
		  msg.post;
			this.readBuf(msg[1]);
		});
		
		this.addCommand("duration", "f", { arg msg;
      duration = msg[1];
    });
    
    this.addCommand("pan", "f", { arg msg;
      pan = msg[1];
    });
    
   	this.addCommand("rate", "f", { arg msg;
   	var val;
   	val = msg[1];
      Synth("agrain", [\out, context.out_b, \bufnum,whichBuf,\pchRatio,val,\start,start,\panSpeed, pan, \duration,duration,\amp,amp], target:pg);
    });
    
    this.addCommand("whichBuffer", "i", { arg msg;
      if(msg[1] == 1,
      {whichBuf = recBuffer; length = recBuffer.numFrames},
      {whichBuf = buffer; length = buffer.numFrames}
      )
    });
    
    this.addCommand("pitchDisp", "f", { arg msg;
      pitchDisp = msg[1];
    });
    
    this.addCommand("pitchQ", "f", { arg msg;
      pitchQ = msg[1];
    });
		
		this.addCommand("start", "f", { arg msg;
      start = msg[1];
    });
    
    this.addCommand("timeDisp", "f", { arg msg;
      timeDisp = msg[1];
    });
    
    this.addCommand("amp", "f", { arg msg;
      amp = msg[1];
    });
    
    
    this.addPoll("length".asSymbol, {
				var val = length;
				val
			});
			
			
		
 }




	free {
            synth.free;
	}

} 
