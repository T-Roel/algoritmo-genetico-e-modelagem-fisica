/*
# -*- coding: utf-8 -*-

Código demonstração de Algoritmo Genético e Modelagem Física

Thales Roel - thalesroel@hotmail.com
*/

Quarks.install("https://github.com/supercollider-quarks/MathLib"); //instalar para obter a colecao .variance

//mede a adequacao dos cromossomos
(
~adequacao = {arg del;
	var mean, vari, mo=3.5, vo=5.5, fitness;

	mean= del.mean;
	vari= del.variance;
	(mo-mean); //obtemos a diferenca entre a média objetiva e a média calculada
	(vo - vari); //obtemos a diferenca entre a variancia objetiva e a calculada

	//Elevamos ao quadrado para provocar que o erro incremente quanto maior ele for
	fitness = pow((mo-mean), 2) + pow((vo - vari), 2);
};
)

//Abaixo é aplicado uma população inicial de 100 cromossomos
//Obtem-se uma lista delta para cara elemento que é utilizado para medir sua adequacao

(
//100 listas com 12 elementos que possuem valores aleatórios entre 0 e 14
~populacao = Array.fill(100, {Array.fill(12, { rrand(0,14)})});
~nGeracoes = 0;
~geracoes = Array.new;

~deriva = {arg populacao = Array.fill(100, {Array.fill(12, { rrand(0,14)})});
	var aptos, adequacoes, adequacaoAptos, pSize, novaPop;

	adequacoes = Array.newClear(populacao.size);
	//não sabemos quantos aptos vao aparecer na pop inicial
	aptos = Array.new;
	adequacaoAptos = Array.new;

	populacao.do({|cromo, n|
		var delta, adequacao;
		//delta é uma lista do menor elemento de cada cromossomo
		delta = Array.newClear(cromo.size-1);

		//calcula o delta de cada cromo
		cromo.do({|item, i|
			if(i < (cromo.size-1),
			{
				delta[i] = abs(item-cromo[i+1])
			});
		});

		//agora utiliza o delta para calcular sua adequacao utilizando a
		//funcao adequacao que declaramos anteriormente
		adequacoes[n] = ~adequacao.value(delta);
		//finalmente aplica a regra de sobrevivencia, se é apto
		//passa ao processo de evolução
		if(adequacoes[n] < 8,
			{
				aptos = aptos.add(cromo);
				adequacaoAptos = adequacaoAptos.add(adequacoes[n]);
		});
	});

	//adequacoes.plot;
	//adequacaoAptos.plot;
	pSize = aptos.size;

	//agora os aptos contem os cromossomos que cumprem com a funcao de adequacao
	//que definimos a principio

	//agora devemos aplicá-los um processo de evolucao, com recombinacao e mutacao

	//Recombinacao
	//Vamos mesclar genes de um cromossomo do principio da lista de aptos com um do final
	//se o número de cromossomos é nom, o cromossomo do meio da lista ficará sem trocar,
	//pois não há com quem trocar

	novaPop = Array.new;

	((pSize/2).floor).do({|i|

		var ranPos, pair, reverseIndx, crom1, crom2;

		reverseIndx = (pSize-(i+1));
		crom1 = aptos[i];
		crom2 = aptos[reverseIndx];

		//elegemos uma posicao aleatória para
		//recombinar elementos do cromossomo
		//fazemos isso 3 vezes
		3.do({
			var val1, val2, randPos;

			randPos = rrand(0, (crom1.size-1));
			val1 = crom1[randPos];
			val2 = crom2[randPos];
			crom1[randPos] = val2;
			crom2[randPos] = val1;
		});

		novaPop = novaPop.add(crom1);
		novaPop = novaPop.add(crom2);

	});

	//Mutacao e geracao de novos individuos
	//com base nos individuos aptos aplicamos uma funcao de mutacao

	aptos.do({|item, i|
		var new, temp1, temp2, splitIndx;

		//aplica 3 mutacoes, cada um produz um novo individuo
		//troca de lugar dois elementos aleatorios do cromossomo
		new = item.swap((rrand(0, item.size-1)), (rrand(0, item.size-1)));
		novaPop = novaPop.add(new);

		// multplica por 2 e aplica o modulo para que nao rebace
		// o range de valores selecionados no inicio.
		//new = item.collect({|it, n| (it*2)%15});
		//nuevaPob = nuevaPob.add(new);

		// Divide em dois a lista e troca de posicao as duas partes
		//splitIndx = rrand(0, item.size-1);
		//temp1 = item[0..(splitIndx-1)];
		//temp2 = item[splitIndx..((item.size)-1)];
		//new = temp2++temp1;

		new = new[0..11];


		novaPop = novaPop.add(new);

	});

	//Manda chamar a funcao de maneira recursiva para produzir uma nova populacao
	~nGeracoes = ~nGeracoes+1;
	~geracoes = ~geracoes.add(novaPop);

	if(~nGeracoes < 10,
		{
			~deriva.value(novaPop);
	});

	novaPop;
};

//Mandamos chamar a funcao
~deriva.value(~populacao);
)

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