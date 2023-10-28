GeneticAlgorithm {

	var <>numGenerations, <>generations; // <> = get and set

	*new {
		arg numGenerations, generations;
		^super.newCopyArgs(numGenerations, generations);
	}

	createNewPopulation {
		arg population, mean=3.5, variance=5.5, typeOfMutation='changePosition', qtyGen=10, fitness=8, amtRecombination=3;
		var fit, adjustments, fitAdjustments, popSize, newPop;

		adjustments = Array.newClear(population.size);
		// We don't know how many candidates will appear in the initial pop
		fit = Array.new;
		fitAdjustments = Array.new;

		population.do(
			{
				arg chromo, n;
				var delta, adequacy;
				// delta is a list of the smallest element of each chromosome
				delta = Array.newClear(chromo.size-1);

				// calculate delta for each chromo
				chromo.do(
					{
						arg item, index;
						if(index < (chromo.size-1),
							{
								delta[index] = abs(item-chromo[index+1])
							}
						);
					}
				);

				// now uses the delta to calculate its suitability
				adjustments[n] = this.calculateFitness(mean, variance, delta);

				// finally applies the survival rule, if it is fit it goes through the evolution process
				if(adjustments[n] < fitness,
					{
						fit = fit.add(chromo);
						fitAdjustments = fitAdjustments.add(adjustments[n]);
					}
				);
			}
		);

		popSize = fit.size;

		/*
		now the fit ones contain the chromosomes that fulfill the fitness function
		that we defined at the beginning. Therefore, we must apply them a process
		of evolution, with recombination and mutation.

		Recombination
		Let's merge genes from a chromosome at the beginning of the fit list with one at the end
		if the number of chromosomes is nom, the chromosome in the middle of the list will remain
		without changing, because there is no one to exchange with

		Mutation
		It is the generation of new individuals based on suitable individuals, we apply a mutation
		function
		*/
		newPop = this.recombine(popSize, fit, amtRecombination);
		newPop = this.mutate(fit, typeOfMutation, newPop);

		//Manda chamar a funcao de maneira recursiva para produzir uma nova populacao
		this.numGenerations = this.numGenerations+1;
		this.generations = this.generations.add(newPop);

		if(this.numGenerations < qtyGen,
			{
				this.createNewPopulation(newPop, mean, variance, typeOfMutation);
		});

		^newPop;
	}

	calculateFitness { // measures the adequacy of chromosomes
		arg objectiveMean, objectiveVariance, delta;
		var calculateMean, calculateVariance, diffMean, diffVariance, fitness;

		calculateMean = delta.mean;
		calculateVariance = delta.variance;
		diffMean = (objectiveMean - calculateMean); // we obtain the difference between the objective mean and the calculated mean
		diffVariance = (objectiveVariance - calculateVariance); // we obtain the difference between the objective and the calculated variance

		// We square it to cause the error to increase the larger it is
		fitness = pow(diffMean, 2) + pow(diffVariance, 2);
		^fitness;
	}

	recombine {
		arg popSize, fit, amtRecombination;
		var newPop;
		newPop = Array.new;
		((popSize/2).floor).do(
			{
				|index|
				var ranPos, pair, reverseIndx, chromOne, chromTwo;

				reverseIndx = (popSize-(index+1));
				chromOne = fit[index];
				chromTwo = fit[reverseIndx];

				// we choose a random position to recombine chromosome elements
				amtRecombination.do({
					var valOne, valTwo, randPos;

					randPos = rrand(0, (chromOne.size-1));
					valOne = chromOne[randPos];
					valTwo = chromTwo[randPos];
					chromOne[randPos] = valTwo;
					chromTwo[randPos] = valTwo;
				});

				newPop = newPop.add(chromOne);
				newPop = newPop.add(chromTwo);
			}
		);

		^newPop;
	}

	mutate {
		arg fit, typeOfMutation, newPop;
		fit.do(
			{
				arg item, index;
				var new, tempOne, tempTwo, splitIndex;

				switch(
					typeOfMutation,
					'changePosition', {
						// applies 3 mutations, each one produces a new individual and swaps two random elements of the chromosome
						new = item.swap((rrand(0, item.size-1)), (rrand(0, item.size-1)));
						newPop = newPop.add(new);
					},
					'applyModule', {
						// Multiply by 2 and apply the modulus so that it does not exceed the range of values ​​selected at the beginning.
						new = item.collect({|it, n| (it*2)%15});
						newPop = newPop.add(new);
					},
					'divideArray', {
						// Divide the array in two and swap the two parts
						splitIndex = rrand(0, item.size-1);
						tempOne = item[0..(splitIndex-1)];
						tempTwo = item[splitIndex..((item.size)-1)];
						new = tempTwo++tempOne;
					}
				);

				new = new[0..11];

				newPop = newPop.add(new);
			}
		);

		^newPop;
	}
}