#include <stdio.h>
#include <strings.h>
#include <stdlib.h>
#include <math.h>


int main(int argc, char *argv[]) {
	int i;
	int n; // number of replicas
	char filename[1200]; //filename buffer;
	
	char outname[130];
	char buffer[10000];
	char type[10], res[10], atom[10], tmp[10];
	double cA, cB, mA,mB,tl, th, dt, l;
	int nr,cgnr,resnr;
	int at=0;
	FILE *in;
	FILE *out;
	FILE *bond;
	
	strcpy(filename, argv[1]);
	n = atoi(argv[2]);
	tl = atof(argv[3]);
	th = atof(argv[4]);
	
	dt = (th-tl)/n;
	
	
	
	in=fopen(filename, "r");
	
	
	for (i =0; i < n; i++) {
		l = (tl + i*dt)/th;
		sprintf(outname, "./%d/%s", i,filename);
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
		while(at == 1) {
			fgets(buffer,sizeof(buffer),in);
			if (strlen(buffer) < 3) {
				at =0;
				break;
			}
			if(buffer[0] == ';') {
				fprintf(out,"%s",buffer);
				continue;
			}
			sscanf(buffer, "%d %s %d %s %s %d %lf %lf ;", &nr, type, &resnr, &res, atom, &cgnr, &cA, &mA);
			cB = cA * sqrt(l);
			mB = mA;
			fprintf(out, "%d\t%s\t%d\t%s\t%s\t%d\t%lf\t%lf\tp%s\t%lf\t%lf\n", nr, type, resnr, res, atom, cgnr, cA, mA, type, cB, mB);
		}
		while(!feof(in)) {
			fgets(buffer,sizeof(buffer),in);
			fprintf(out, "%s", buffer);		
		}
		fclose(out);
		
		/* Modify the dihedrals of charmm27.ff/ffbonded.itp */
		sprintf(outname, "./%d/charmm27.ff/ffbonded.itp", i);
		bond = fopen(outname, "r");
		sprintf(outname, "./%d/charmm27.ff/ffbonded.itp.new", i);
		out = fopen(outname, "w");
		printf("Building %s\n", outname);
		
		while(fgets(buffer,sizeof(buffer),bond)) {
			fprintf(out, "%s", buffer);
			if (strstr(buffer, "dihedraltypes")) {
				at = 1;
				break;
			}
			
		}
		
		while(at == 1) {
			fgets(buffer,sizeof(buffer),bond);
			if (strlen(buffer) < 3) {
				at =0;
				break;
			}
			if(buffer[0] == ';') {
				fprintf(out,"%s",buffer);
				continue;
			}
			fprintf(out,"%s",buffer);
			sscanf(buffer, "%s %s %s %s %d %lf %lf %d\n", type, res, atom, tmp,&cgnr, &cA, &mA, &nr);
			mA = mA *l;
			fprintf(out, "p%s\tp%s\tp%s\tp%s\t%d\t%3.2lf\t%lf\t%d\n", type, res, atom, tmp, cgnr, cA, mA, nr);
		}
		while(!feof(bond)) {
			fgets(buffer,sizeof(buffer),bond);
			fprintf(out, "%s", buffer);		
		}
		fclose(out);
		fclose(bond);
		
		
		sprintf(outname, "./test.mdp");
		bond = fopen(outname, "r");
		sprintf(outname, "./%d/test.mdp", i);
		out = fopen(outname, "w");
		
		
		while(!feof(bond)){
			fgets(buffer,sizeof(buffer),bond);
			fprintf(out, "%s", buffer);		
		}
		
		fprintf(out, "free-energy = yes\n");
		fprintf(out, "init_lambda=%3.2lf\n", (double)i/n);
		fprintf(out, "delta_lambda = 0\n");
		fprintf(out,"sc_alpha = 0\n");
		fprintf(out,"sc_power = 0 \n");
		fprintf(out,"sc_sigma = 0.3\n");
		
		fclose(out);
		fclose(bond);
		
	}
	return(0);
}

			
			
			
			
			
