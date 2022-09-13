/*
# -*- coding: utf-8 -*-

Código demonstração de Algoritmo Genético e Modelagem Física

Thales Roel - thalesroel@hotmail.com
*/

Quarks.install("https://github.com/supercollider-quarks/MathLib"); //instalar para obter a colecao .variance

//Abaixo é aplicado uma população inicial de 100 cromossomos
//Obtem-se uma lista delta para cara elemento que é utilizado para medir sua adequacao

~delta = Array.new(5);
~delta.add(3);
~delta.add(6);
~delta.add(19);
~teste = GeneticAlgorithm.new;
~teste.nGeracoes_(0);
~teste.geracoes_(Array.new);

~teste.calculaFitness(delta: ~delta);
~teste.calculaFitness(2.1,4.3, ~delta);
//100 listas com 12 elementos que possuem valores aleatórios entre 0 e 14
~teste.deriva(Array.fill(100, {Array.fill(12, { rrand(0,14)})}));

Scale.directory

//aplicando síntese por modelagem física

(
~scale = Scale.mixolydian.degrees;

SynthDef(\xylophone, {
	arg freq = 440, amp = 0.01, pan = 0, out = 0, att = 0.001, rel = 2, exciterRel = 0.05;

	var exciter, snd;

	exciter = Impulse.ar(0);

	snd = DynKlank.ar(
		specificationsArrayRef:
	        	Ref.new([
	        		[1, 3, 3.971, 5.024, 5.903, 7.13, 8.91],   // harmonicos
			        [1, 0.95, 0.0891, 0.65, 0.794, 0.53, 0.1], // amplitudes
		        	[1, 0.593, 0.19, 0.16, 0.26, 0.02, 0.05]     // ring times
		        ]),
		input: exciter,
		freqscale: freq,
		decayscale: rel
	);

	DetectSilence.ar(
		        in: snd,
		        amp: 0.001,
		        time: 0.5,
		        doneAction: 2
		    );

	Out.ar(out, Pan2.ar(snd, pan, amp));
};
).add;

SynthDef(\marimba1, {
	arg
	// Valores Padrões
	freq = 440, out = 0, amp = 0.4, pan = 0, rq = 0.02,
        // Controles para BLowShelf
	shelffreq = 220, rs = 0.81, shelfamp = 2;

	var snd;

	snd = BPF.ar(
		in: Saw.ar(0),
		freq: freq,
		rq: rq);

	snd = BLowShelf.ar(
		in: snd,
		freq: shelffreq,
		rs: rs,
		db: shelfamp.ampdb);

	snd = Limiter.ar(snd) * amp;

	DetectSilence.ar(in: snd, doneAction: 2);

	Out.ar(out, Pan2.ar(snd, pan));
};
).add;

SynthDef(\kalimba, {
	arg
	// Valores padrões
	out = 0, freq = 440, amp = 0.1, att = 0.001, rel = 3, pan = 0, crv = -8,
	// Outros controles (controle mix vai de 0 a 1)
	mix = 0.1, clickRel = 0.01;

	var note, env, body, snd;

	env = Env.perc(
		attackTime:att * 3, releaseTime: rel,
		curve: crv).kr(doneAction: 2);

	note = SinOsc.ar(freq) * env;

	body = DynKlank.ar(
		specificationsArrayRef:
		Ref.new([
			[240 * ExpRand(0.9, 1.1), 2020 * ExpRand(0.9, 1.1), 3151 * ExpRand(0.9, 1.1)],
			[-7, 0, 3].dbamp, // mesmo que 10.pow([-7, 0, 3] / 20),
			[0.75, 0.04, 0.06] + clickRel
		]),
		input:

		(PinkNoise.ar * Env.perc(att, clickRel).kr)
	);

	snd = (note * (1 - mix)) + (body * mix) * amp;

	DetectSilence.ar(in: snd, doneAction: 2);

	Out.ar(out, Pan2.ar(snd, pan));
};
).add;

SynthDef(\pmCrotales, {
	arg out = 0, freq = 261, tone = 3, att = 0, rel = 2, curve = -6, amp = 0.8, pan = 0, modLo = 5.25, modHi = 5.5;

	var env, snd, mod;

	env = Env.perc(attackTime: 0, releaseTime: rel, curve: curve).kr(doneAction: 2);

	mod = Rand(modLo, modHi);

	snd = PMOsc.ar(
	    	carfreq: freq,
	    	modfreq: mod * freq,
	    	pmindex: env * tone,
	    	mul: env * amp
	    );

	snd = HPF.ar(snd, freq / 2);

	snd = Mix.ar(snd) * 0.1;

	Out.ar(out, Pan2.ar(snd, pan));
};
).add;

{
	~geracoes.do({|generacion, i|

		generacion.do({|cromo, j|
			cromo.postln;
			~marimba = Pbind(\instrument, \marimba1,
				\octave, 5,
				\scale, ~scale,
				\degree, Pseq(cromo, 1),
				\amp, 0.4,
				\dur, 0.5

			);

			~xilo = Pbind(\instrument, \xylophone,
				\octave, 6,
				\scale, ~scale,
				\degree, Pseq(cromo, 1),
				\amp, 0.3,
				\dur, 1

			);

			~kalimba = Pbind(\instrument, \kalimba,
				\octave, 4,
				\scale, ~scale,
				\degree, Pseq(cromo, 1),
				\amp, 0.3,
				\dur, 0.75

			);

			~crotales = Pbind(\instrument, \pmCrotales,
				\octave, 8,
				\scale, ~scale,
				\degree, Pseq(cromo, 1),
				\amp, 0.3,
				\dur, 0.25

			);

			Ppar([~marimba, ~xilo, ~kalimba, ~crotales]).play;
			(0.5*cromo.size).wait;
		})
	})
}.fork
)

//gravar o áudio gerado direto do servidor
s.makeWindow