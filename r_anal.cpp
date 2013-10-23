#include <iostream>
#include <fstream>
#include <cstdio>
#include <iomanip>
#include <cstring>
using namespace std;

int main(int argc, char *argv[])
{
  cout << "To use this program you need to have entered ./program_name file_name"<<endl;
  cout<<"This file should contain the output from g_rama with the text at the top removed"<<endl;

  if(argc != 2) {
    cout << "program requires command line file which is the output from g_rama with the text at teh top of the file removed\n";
    return 1;}

  // int num =200;
  long num;
  char buffer[256];
  double phi[200000];
  double psi[200000];
  char str[200000][8];

  cout <<endl;
  cout<<endl;
  cout<<"Enter number of lines in your g_rama output file (the one without the text lines at the top):"<<endl;
  cin >> num;

  ifstream in1(argv[1], ios::in | ios::binary);
  if(!in1) {
    cout << "Cannot open input file\n";
    return 1;}

  for(int i=0; i<num; i++){
    in1 >>phi[i]>>psi[i]>>str[i];
    in1.getline(buffer,256);
  }
  in1.close();

  double *hi;
  double *si;
  long *count;
  count = (long*) malloc (sizeof(long)*num);
  hi = (double*) malloc (sizeof(double)*num);
  si = (double*) malloc (sizeof(double)*num);

  static long c=0;

  for (int i=0; i<num; i++){
    if(phi[i] != 200 && psi[i] != 200){
      for(int j=i+1; j<num; j++){
	if((phi[i] <= (phi[j]+0.50) && phi[i] >= (phi[j]-0.50)) && (psi[i] <=(psi[j]+0.50) && psi[i] >= (psi[j]-0.50))){
	  //cout << "found a match"<<endl;
	count[c]= count[c] +1;
	//now need to remove phi[j], psi[j] from list so that don't recount these
	phi[j] = 200;
	psi[j] = 200;
	}
      }   
      hi[c] = phi[i];
      si[c] = psi[i];
      c++;
    }
  }


    ofstream out("density_plot", ios::out |ios::binary);
    if(!out) {
      cout <<"cannot open short_bonds";
      return 1;}
    out.setf(ios::fixed, ios::floatfield);

    out << "@target G0.S0"<<endl;
    out << "@type xy"<<endl;

  for(int i=0; i<c; i++) {
    if(count[i]<2){
      out<<setw(5)<<setprecision(4)<<setw(10)<<hi[i]<<setw(10)<<si[i]<<endl;}}
  out << "&"<<endl;
  out << "@target G0.S1"<<endl;
  out << "@type xy"<<endl;

  for(int i=0; i<c; i++) {
    if(count[i]<5 && count[i] >=2){
      out<<setw(5)<<setprecision(4)<<setw(10)<<hi[i]<<setw(10)<<si[i]<<endl;}}
out << "&"<<endl;
 out << "@target G0.S2"<<endl;
  out << "@type xy"<<endl;
  for(int i=0; i<c; i++) {
    if(count[i]<10 && count[i] >=5){
      out<<setw(5)<<setprecision(4)<<setw(10)<<hi[i]<<setw(10)<<si[i]<<endl;}}	
out << "&"<<endl;
 out << "@target G0.S3"<<endl;
  out << "@type xy"<<endl;
  for(int i=0; i<c; i++) {
    if(count[i]<15 && count[i] >= 10){
      out<<setw(5)<<setprecision(4)<<setw(10)<<hi[i]<<setw(10)<<si[i]<<endl;}}
out << "&"<<endl;
 out << "@target G0.S4"<<endl;
  out << "@type xy"<<endl;
  for(int i=0; i<c; i++) {
     if(count[i]<20 && count[i] >= 15){
       out<<setw(5)<<setprecision(4)<<setw(10)<<hi[i]<<setw(10)<<si[i]<<endl;}}
out << "&"<<endl;
 out << "@target G0.S5"<<endl;
  out << "@type xy"<<endl;

  for(int i=0; i<c; i++) {
    if(count[i]<30 && count[i] >= 20){
      out<<setw(5)<<setprecision(4)<<setw(10)<<hi[i]<<setw(10)<<si[i]<<endl;}}
out << "&"<<endl;
  out << "@target G0.S6"<<endl;
  out << "@type xy"<<endl;
  for(int i=0; i<c; i++) {
    if(count[i] >= 30){
      out<<setw(5)<<setprecision(4)<<setw(10)<<hi[i]<<setw(10)<<si[i]<<endl;}
 }  
out << "&"<<endl;
  out.close();


  cout << "To make a colour plot enter:"<<endl;
  cout<< "cat head_rama density_plot > file_output_name.xvg"<<endl;

  return 0;
}
