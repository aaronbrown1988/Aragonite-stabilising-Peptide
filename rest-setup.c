#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#define CHARMM 1
#define DB 0
#define DEBUG if(DB==1)

int main(int argc, char *argv[]) {
	int i, j;
	int rv;
	int n; // number of replicas
	int ntypes;
	int found;
	char filename[1200]; //filename buffer;
	
	char outname[130];
	char buffer[10000];
	char **types;
	char type[10], res[10], atom[10], tmp[10];
	double cA, cB, mA,mB,tl, th, dt, l, sig, eps;
	int nr,cgnr,resnr;
	int at=0;
	FILE *in;
	FILE *out;
	FILE *bond;


	if(argc!= 6) {
		printf("USAGE rest-setup BASE.top rep_ID total_replicas TL TH\n");
		printf("Setups REST replica exchange from a folder containing the base .top and the starting configurations");
		exit(EXIT_FAILURE);
	}		
	
	
	strcpy(filename, argv[1]);
	i = atoi(argv[2]);
	n = atoi(argv[3]);
	tl = atof(argv[4]);
	th = atof(argv[5]);
	
	dt = (th-tl)/n;
	
	types = malloc(sizeof(char*)*1000);

	in=fopen(filename, "r");
	if(in == (FILE*) NULL) {
		fprintf(stderr, "Couldn't open %s\n", filename);
		exit(EXIT_FAILURE);
	}
	
	ntypes = 1;
	types[0] = malloc(sizeof(char)*2);
	types[0] = "X";
	l = tl/th; //(tl + i*dt)/th;
	sprintf(outname, "./%s.new", filename);
	printf("Generating %s\n", outname);
	out = fopen(outname, "w");
	rewind(in);
	
	while(fgets(buffer,sizeof(buffer),in)) {
		fprintf(out, "%s", buffer);
		if (strstr(buffer, "atoms")) {
			at = 1;
			break;
		}
		
	}
	printf("atoms section found!\n");
	while(at == 1 && (!feof(in))) {
		fgets(buffer,sizeof(buffer),in);
		if (strlen(buffer) < 3) {
			at =0;
			break;
		}
		if(buffer[0] == ';') {
			fprintf(out,"%s",buffer);
			continue;
		}
		sscanf(buffer, "%d %s %d %s %s %d %lf %lf ;", &nr, type, &resnr, res, atom, &cgnr, &cA, &mA);
		

		//Build list of new types
		found = 0;
		for (j =0; j < ntypes; j++) {
			if (strstr(types[j], type)) {
				found = 1;
				DEBUG printf("found %s\n", type);
				break;
			}
		}
		
		if (found == 0) {
			// new atom type
			types[ntypes] = malloc(strlen(type)*sizeof(char));
			strcpy(types[ntypes], type);
			ntypes++;
//			printf("%s\n",type);
		}

		cB = cA * sqrt(l);
		mB = mA;
		//fprintf(out, "%d\t%s\t%d\t%s\t%s\t%d\t%lf\t%lf\tp%s\t%lf\t%lf\n", nr, type, resnr, res, atom, cgnr, cA, mA, type, cB, mB);
//		fprintf(out, "%d\t%s\t%d\t%s\t%s\t%d\t%lf\t%lf\t%sp\t%lf\t%lf\n", nr, type, resnr, res, atom, cgnr, cA, mA, type, cB, mB);
		fprintf(out, "%d\t%s\t%d\t%s\t%s\t%d\t%lf\t%lf\t%s\t%lf\t%lf\n", nr, type, resnr, res, atom, cgnr, cA, mA, type, cB, mB);
	}
		fgets(buffer,sizeof(buffer),in);
	while(!feof(in)) {
		fprintf(out, "%s", buffer);		
		fgets(buffer,sizeof(buffer),in);
	}
	fclose(out);
	
	/* Modify the dihedrals of charmm27.ff/ffbonded.itp */
	#ifdef CHARMM
	sprintf(outname, "./charmm27.ff/ffbonded.itp");
	#endif
	#ifdef AMBER
	sprintf(outname, "./amber03.ff/ffbonded.itp");
	#endif
	bond = fopen(outname, "r");
	#ifdef CHARMM
	sprintf(outname, "./charmm27.ff/ffbonded.itp.new");
	#endif
	#ifdef AMBER
	sprintf(outname, "./amber03.ff/ffbonded.itp.new");
	#endif
	out = fopen(outname, "w");
	printf("Building %s", outname);

	if(bond == (FILE*)NULL ) {
		fprintf(stderr, "Couldn't open ffbonded.itp in forcefield folder\n");
		exit(EXIT_FAILURE);
	}




	while(fgets(buffer,sizeof(buffer),bond)) {
		fprintf(out, "%s", buffer);
		if (strstr(buffer, "bondtypes")) {
			at = 1;
			break;
		}
		
	}
	printf("..bond types..");	
	while(at == 1&&(!feof(bond))) {
		fgets(buffer,sizeof(buffer),bond);
		if (strlen(buffer) < 3) {
			at =0;
			break;
		}
		if(buffer[0] == ';') {
			fprintf(out,"%s",buffer);
			continue;
		}
	//	fprintf(out,"%s",buffer);
		sscanf(buffer, "%s %s  %d %lf %lf \n", type, res, &cgnr, &cA, &mA);
		

		//horrificlly inefficient way to do this 
		found = 0;
		for (j =0; j < ntypes; j ++) {
			if (strstr(types[j], type)) {
				found++;
				break;
			}
		}
		for (j =0; j < ntypes; j ++) {
			if (strstr(types[j], res)) {
				found++;
				break;
			}
		}
		if (found == 2) {
			//mA = mA *l;
			fprintf(out, "%s\t%s\t%d\t%3.2lf\t%lf\t%3.2lf\t%3.2lf\n", type, res,  cgnr, cA, mA, cA, mA*l);
			DEBUG printf("Matched bond %s %s\n", type, res);
		} else {
			fprintf(out, "%s\t%s\t%d\t%3.2lf\t%3.2lf\n", type, res,  cgnr, cA, mA, cA, mA );
		}
	}




	while(fgets(buffer,sizeof(buffer),bond)) {
		fprintf(out, "%s", buffer);
		if (strstr(buffer, "angletypes")) {
			at = 1;
			break;
		}
		
	}

	printf("..angles...");
	while(at == 1 && (!feof(bond))) {
		fgets(buffer,sizeof(buffer),bond);
		if (strlen(buffer) < 3) {
			at =0;
			break;
		}
		if(buffer[0] == ';') {
			fprintf(out,"%s",buffer);
			continue;
		}
//		fprintf(out,"%s",buffer);
		rv =0;
		rv =  sscanf(buffer, "%s %s %s %d %lf %lf %lf %lf\n", type, res, atom, &cgnr, &cA, &mA, &cB, &mB);
		/* horrificlly inefficient way to do this */
		found = 0;
		for (j =0; j < ntypes; j ++) {
			if (strstr(types[j], type)) {
				found++;
				break;
			}
		}
		for (j =0; j < ntypes; j ++) {
			if (strstr(types[j], res)) {
				found++;
				break;
			}
		}
		for (j =0; j < ntypes; j ++) {
			if (strstr(types[j], atom)) {
				found++;
				break;
			}
		}
		if (found == 3) {
			fprintf(out, "%s\t%s\t%s\t%d\t%3.2lf\t%lf\t%3.2lf\t%3.2lf\t%3.2lf\t%3.2lf\t%3.2lf\t%3.2lf\n", type, res, atom, cgnr, cA, mA, cB, mB, cA, mA *l, cB, mB*l);
		} else {
			fprintf(out, "%s\t%s\t%s\t%d\t%3.2lf\t%lf\t%lf\t%lf ; untouched\n", type, res, atom, cgnr, cA, mA, cB,mB);
		}
		
	}







	while(fgets(buffer,sizeof(buffer),bond)) {
		fprintf(out, "%s", buffer);
		if (strstr(buffer, "dihedraltypes")) {
			at = 1;
			break;
		}
		
	}

	printf("..dihedrals...");
	while(at == 1 && (!feof(bond))) {
		fgets(buffer,sizeof(buffer),bond);
		if (strlen(buffer) < 3) {
			at =0;
			break;
		}
		if(buffer[0] == ';') {
			fprintf(out,"%s",buffer);
			continue;
		}
//		fprintf(out,"%s",buffer);
		rv =0;
		rv =  sscanf(buffer, "%s %s %s %s %d %lf %lf %d\n", type, res, atom, tmp,&cgnr, &cA, &mA, &nr);
		nr = (rv != 8)? NULL:nr;
		/* horrificlly inefficient way to do this */
		found = 0;
		for (j =0; j < ntypes; j ++) {
			if (strstr(types[j], type)) {
				found++;
				break;
			}
		}
		for (j =0; j < ntypes; j ++) {
			if (strstr(types[j], res)) {
				found++;
				break;
			}
		}
		for (j =0; j < ntypes; j ++) {
			if (strstr(types[j], atom)) {
				found++;
				break;
			}
		}
		for (j =0; j < ntypes; j ++) {
			if (strstr(types[j], tmp)) {
				found++;
				break;
			}
		}
		if (found == 4) {
		/*	mA = mA *l;
			if (strstr(type,"X") && strstr(tmp, "X")  ) {
				fprintf(out, "%s\t%sp\t%sp\t%s\t%d\t%3.2lf\t%lf\t%d\n", type, res, atom, tmp, cgnr, cA, mA, nr);
			}else if (strstr(res,"X") && strstr(atom, "X")  ) {
				fprintf(out, "%sp\t%s\t%s\t%sp\t%d\t%3.2lf\t%lf\n", type, res, atom, tmp, cgnr, cA, mA);
			} else if (cgnr == 2) {
				fprintf(out, "%sp\t%sp\t%sp\t%sp\t%d\t%3.2lf\t%lf\n", type, res, atom, tmp, cgnr, cA, mA);
			} else {
				fprintf(out, "%sp\t%sp\t%sp\t%sp\t%d\t%3.2lf\t%lf\t%d\n", type, res, atom, tmp, cgnr, cA, mA, nr);
			}
//			printf("Matched Dihedral %s %s %s %s\n", type, res,atom, tmp); */
			if(cgnr == 2) {
				fprintf(out, "%s\t%s\t%s\t%s\t%d\t%3.2lf\t%lf\t%3.2lf\t%3.2lf\n", type, res, atom, tmp, cgnr, cA, mA,  cA, mA *l);
				//fprintf(out, "%s\t%s\t%s\t%s\t%d\t%3.2lf\t%lf\t%d\t%3.2lf\t%3.2lf\n", type, res, atom, tmp, cgnr, cA, mA, cgnr, cA, mA *l);
			} else {
				//fprintf(out, "%s\t%s\t%s\t%s\t%d\t%3.2lf\t%lf\t%d\t%d\t%3.2lf\t%3.2lf\t%d\n", type, res, atom, tmp, cgnr, cA, mA, nr, cgnr,cA,mA * l,nr);
				fprintf(out, "%s\t%s\t%s\t%s\t%d\t%3.2lf\t%lf\t%d\t%3.2lf\t%3.2lf\t%d\n", type, res, atom, tmp, cgnr, cA, mA, nr, cA,mA * l,nr);
			}	
		} else {
			if(cgnr == 2) {

				fprintf(out, "%s\t%s\t%s\t%s\t%d\t%3.2lf\t%lf ; untouched\n", type, res, atom, tmp, cgnr, cA, mA);
			} else {
				fprintf(out, "%s\t%s\t%s\t%s\t%d\t%3.2lf\t%lf\t%d ; untouched\n", type, res, atom, tmp, cgnr, cA, mA, nr);
			}
		}
		
	}
/*	rewind(bond);

	while(fgets(buffer,sizeof(buffer),bond)) {
	//	fprintf(out, "%s", buffer);
		if (strstr(buffer, "dihedraltypes")) {
			at = 1;
			break;
		}
		
	}
	while(at ==1 &&(!feof(bond))) {
		fgets(buffer,sizeof(buffer),bond);
		if (strlen(buffer) < 3) {
			at =0;
			break;
		}
		fprintf(out, "%s",buffer);
	
	} */
	printf("..other bits..");
	while(!feof(bond)) {
		fgets(buffer,sizeof(buffer),bond);
		fprintf(out, "%s", buffer);		
	}
	fclose(out);
	fclose(bond);
	printf("done!\n");

	


	 // Modify charmm27.ff/ffnonbonded.itp 
	
	 #ifdef CHARMM
	sprintf(outname, "./charmm27.ff/ffnonbonded.itp");
	#endif
	
	#ifdef AMBER 
	sprintf(outname, "./amber03.ff/ffnonbonded.itp");
	
	#endif
	
	bond = fopen(outname, "r");
	
	#ifdef CHARMM
	sprintf(outname, "./charmm27.ff/ffnonbonded.itp.new");
	#endif
	
	#ifdef AMBER
	sprintf(outname, "./amber03.ff/ffnonbonded.itp.new");
	#endif
	
	out = fopen(outname, "w");
	printf("Building %s", outname);

	if (out == (FILE*)NULL) {
		fprintf(stderr, "Couldn't open nonbonded output file\n");
		exit(EXIT_FAILURE);
	}
	if(bond == (FILE*)NULL ) {
		fprintf(stderr, "Couldn't open ffbonded.itp in charmm folder\n");
		exit(EXIT_FAILURE);
	}
	
	while(fgets(buffer,sizeof(buffer),bond)) {
		fprintf(out, "%s", buffer);
		if (strstr(buffer, "atomtypes")) {
			at = 1;
			break;
			}
		
	}
	
	printf("..atom types..");
		
	while(at == 1) {
		fgets(buffer,sizeof(buffer),bond);
		if (strlen(buffer) < 3) {
			at =0;
			break;
		}
		if(buffer[0] == ';'|| buffer[0] == '#') {
			fprintf(out,"%s",buffer);
			continue;
			}
		//fprintf(out,"%s",buffer);
		sscanf(buffer, "%s %d %lf %lf %s %lf %lf \n", type, &cgnr, &mA, &cA, res , &sig, &eps);
		found = 0;
		for (j =0; j < ntypes; j ++) {
			if (strstr(types[j], type)) {
				found++;
				break;
			}
		}
		if (found ==1) {
			//cA = cA * sqrt(l);
			//sig = sig * l;
			//eps = eps*l;
			fprintf(out, "%s\t%d\t%3.2lf\t%lf\t%s\t%lf\t%lf\t%lf\t%lf\t%lf\n", type, cgnr, mA, cA, res, sig, eps, cA*sqrt(l), sig*l, eps*l);
		} else {
			fprintf(out, "%s\t%d\t%3.2lf\t%lf\t%s\t%lf\t%lf\n", type, cgnr, mA, cA, res, sig, eps);
		}

	}	

	// pair types
	#ifdef CHARMM
	while(fgets(buffer,sizeof(buffer),bond)) {
		fprintf(out, "%s", buffer);
		if (strstr(buffer, "pairtypes")) {
			at = 1;
			break;
			}
		
	}
	printf("..pair types..");	
	while(at == 1 && (!feof(bond))) {
		fgets(buffer,sizeof(buffer),bond);
		if (strlen(buffer) < 3) {
			at =0;
			break;
		}
		if(buffer[0] == ';' || buffer[0] == '#') {
			fprintf(out,"%s",buffer);
			continue;
			}
	//	fprintf(out,"%s",buffer);
		sscanf(buffer, "%s %s %d %lf %lf \n", type, res, &nr , &sig, &eps);
		found = 0;
		for (j =0; j < ntypes; j ++) {
			if (strstr(types[j], type)) {
				found++;
				break;
			}
		}
		for (j =0; j < ntypes; j ++) {
			if (strstr(types[j], res)) {
				found++;
				break;
			}
		}
		if (found ==2) {
//			sig = sig * l;
//			eps = eps*l;
			fprintf(out, "%s\t%s\t%d\t%3.2lf\t%lf\t%3.2lf\t%3.2lf\n", type, res, nr, sig, eps, sig *l , eps *l);
		} else {
			fprintf(out, "%s\t%s\t%d\t%3.2lf\t%lf\n", type, res, nr, sig, eps);
		}

	}	




	printf("..other bits..");
	fgets(buffer,sizeof(buffer),bond);
	while(!feof(bond)) {
		fprintf(out, "%s", buffer);		
		fgets(buffer,sizeof(buffer),bond);
	}
	#endif
	
	sprintf(outname, "../test.mdp");
	bond = fopen(outname, "r");
	sprintf(outname, "./test.mdp");
	out = fopen(outname, "w");
	
	
	while(!feof(bond)){
		fgets(buffer,sizeof(buffer),bond);
		fprintf(out, "%s", buffer);		
	}
	l = i/n;
	fprintf(out, "free-energy = yes\n");
	fprintf(out, "init_lambda=%3.2lf\n", l);
	fprintf(out, "delta_lambda = 0\n");
	fprintf(out,"sc_alpha = 0\n");
	fprintf(out,"sc_power = 0 \n");
	fprintf(out,"sc_sigma = 0.3\n");
	
	fclose(out);
	fclose(bond);

	return(0);
}

			
			
			
			
			
