void
plotMaxwellNaive() {

  gStyle->SetOptStat(0);

  TTree * t = new TTree("t","t");
  t->ReadFile("./data/maxwell.dat", "l0/C:inside/I:l1/C:x/F:l2/C:y/F");
  //t->ReadFile("./data/maxwell_1000_samples_1000.dat", "l0/C:inside/I:l1/C:x/F:l2/C:y/F");

  TCanvas * c = new TCanvas("c","c", 0, 0, 700, 600);
  c->DrawFrame(0.,0.,10.,0.5.);

  t->SetMarkerStyle(20);
  t->SetMarkerSize(0.7);
	     
  t->SetMarkerColor(kRed);
  t->Draw("x:y", "inside==0", "same");
  t->SetMarkerColor(kBlue);
  t->Draw("x:y", "inside==1", "same");

}
