GeneticAlgorithm {

	var <>nGeracoes, <>geracoes; // <> = get and set

	deriva {
		arg populacao;
		var aptos, adequacoes, adequacaoAptos, pSize, novaPop;

		adequacoes = Array.newClear(populacao.size);
		//não sabemos quantos aptos vao aparecer na pop inicial
		aptos = Array.new;
		adequacaoAptos = Array.new;

		populacao.do(
			{
				arg cromo, n;
				var delta, adequacao;
				//delta é uma lista do menor elemento de cada cromossomo
				delta = Array.newClear(cromo.size-1);

				//calcula o delta de cada cromo
				cromo.do(
					{
						arg item, i;
						if(i < (cromo.size-1),
							{
								delta[i] = abs(item-cromo[i+1])
							}
						);
					}
				);

				//agora utiliza o delta para calcular sua adequacao
				adequacoes[n] = this.calculaFitness(delta: delta);
				//finalmente aplica a regra de sobrevivencia, se é apto
				//passa ao processo de evolução
				if(adequacoes[n] < 8,
					{
						aptos = aptos.add(cromo);
						adequacaoAptos = adequacaoAptos.add(adequacoes[n]);
					}
				);
			}
		);

		pSize = aptos.size;

		//agora os aptos contem os cromossomos que cumprem com a funcao de adequacao
		//que definimos a principio

		//agora devemos aplicá-los um processo de evolucao, com recombinacao e mutacao

		//Recombinacao
		//Vamos mesclar genes de um cromossomo do principio da lista de aptos com um do final
		//se o número de cromossomos é nom, o cromossomo do meio da lista ficará sem trocar,
		//pois não há com quem trocar

		novaPop = this.recombinar(pSize, aptos);

		//Mutacao e geracao de novos individuos
		//com base nos individuos aptos aplicamos uma funcao de mutacao

		novaPop = this.mutar(aptos, 'divideLista', novaPop);

		//Manda chamar a funcao de maneira recursiva para produzir uma nova populacao
		this.nGeracoes = this.nGeracoes+1;
		this.geracoes = this.geracoes.add(novaPop);

		if(this.nGeracoes < 10,
			{
				this.deriva(novaPop);
		});

		^novaPop;
	}

	calculaFitness { //mede a adequacao dos cromossomos
		arg mediaObjetiva = 3.5, varianciaObjetiva = 5.5, delta;
		var mediaCalculada, varianciaCalculada, diffMedia, diffVariancia, fitness;

		mediaCalculada = delta.mean;
		varianciaCalculada = delta.variance;
		diffMedia = (mediaObjetiva - mediaCalculada); //obtemos a diferenca entre a média objetiva e a média calculada
		diffVariancia = (varianciaObjetiva - varianciaCalculada); //obtemos a diferenca entre a variancia objetiva e a calculada

		//Elevamos ao quadrado para provocar que o erro incremente quanto maior ele for
		fitness = pow(diffMedia, 2) + pow(diffVariancia, 2);
		^fitness;
	}

	recombinar {
		arg pSize, aptos;
		var novaPop;
		novaPop = Array.new;
		((pSize/2).floor).do(
			{
				|i|
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
			}
		);

		^novaPop;
	}

	mutar {
		arg aptos, tipoMutacao, novaPop;
		aptos.do(
			{
				arg item, i;
				var new, temp1, temp2, splitIndx;

				switch(
					tipoMutacao,
					'trocaPosicao', {
						//aplica 3 mutacoes, cada um produz um novo individuo
						//troca de lugar dois elementos aleatorios do cromossomo
						new = item.swap((rrand(0, item.size-1)), (rrand(0, item.size-1)));
						novaPop = novaPop.add(new);
					},
					'aplicaModulo', {
						// multplica por 2 e aplica o modulo para que nao rebace
						// o range de valores selecionados no inicio.
						new = item.collect({|it, n| (it*2)%15});
						novaPop = novaPop.add(new);
					},
					'divideLista', {
						// Divide em dois a lista e troca de posicao as duas partes
						splitIndx = rrand(0, item.size-1);
						temp1 = item[0..(splitIndx-1)];
						temp2 = item[splitIndx..((item.size)-1)];
						new = temp2++temp1;
					}
				);

				new = new[0..11];

				novaPop = novaPop.add(new);
			}
		);

		^novaPop;
	}
}